-- Edit these first 2 to adjust how much is planted in a pass
-- Probably not fast enough to do more than 3x3
grid_w = 3;
grid_h = 3;

imgOnionBed = "ThisIsAnOnionBed.png";
imgOnionSeeds = "OnionSeeds.png";
imgWaterThese = "WaterThese.png";
imgHarvestThese = "HarvestThese.png";
imgWaterJugs = "IconWaterJugs.png";

loadfile("luaScripts/flax_common.inc")();
loadfile("luaScripts/screen_reader_common.inc")();
loadfile("luaScripts/ui_utils.inc")();

walk_px_x = 112;
walk_px_y = 112;
walk_time = 250;
screen_refresh_time = 50;
water_time = 1200;
harvest_time = 1100;
fill_water_time = 4000;
pass_growth_time = 24000;

-- the onion window
window_w = 191;
window_h = 84;
refresh_down_y_offs = 0;

search_size = 15;
search_dx = {0, -search_size, search_size, -search_size, search_size, -search_size, search_size, 0, 0};
search_dy = {0, -search_size, search_size, search_size, -search_size, 0, 0, -search_size, search_size};

function fillWater(required)
	if (aqueduct_mode) then
		aque = srFindImage("Aqueduct.png", 5000);
		if not aque then
			error 'Could not find aqueduct window.';
		end
		srClickMouseNoMove(aque[0], aque[1]);
		lsSleep(150);
		srReadScreen();
		fill = srFindImage("FillWithWater.png", 5000);
		if ((not fill) and required) then
			error 'Could not find Fill With Wather';
		end
		if fill then
			srClickMouseNoMove(fill[0]+5, fill[1]);
		end
	else
		srClickMouseNoMove(xyFillWater[0], xyFillWater[1]);
		lsSleep(screen_refresh_time);
		srClickMouseNoMove(xyCenter[0] + 10, xyCenter[1] + 20);
		lsSleep(fill_water_time);
	end
	num_waters = 0;
end

function doit()
	num_jugs = promptNumber("How many jugs?", 15);
	num_loops = promptNumber("How many " .. grid_w .. "x" .. grid_h .. " passes?", 5);

	askForWindow("Make sure the plant Onions window is pinned and you are in F8F8 cam zoomed in.  Will plant SE of this location.  'Plant all crops where you stand' must be ON.");
	
	initGlobals();
	num_waters = 0;
	
	srReadScreen();
	xyCenter = getCenterPos();
	
	-- Find plant onions window
	local xyPlantOnions = srFindImage(imgOnionSeeds);
	if not xyPlantOnions then
		error 'Could not find plant window';
	end
	xyPlantOnions[0] = xyPlantOnions[0] + 5;

	-- Find aqudeuct or fill water button, use it
	aque = srFindImage("Aqueduct.png", 5000);
	if not aque then
		aqueduct_mode = nil;
		xyFillWater = srFindImage(imgWaterJugs);
		if not xyFillWater then
			error 'Could not find Aqueduct window OR fill jugs with water icon, you may need to empty 1 jug.';
		else
			-- Use it
			fillWater(nil);
		end;
	else
		aqueduct_mode = 1;
		fillWater(nil);
	end
	
	for loop_count=1, num_loops do
		
		-- Plant and pin
		for y=1, grid_h do
			for x=1, grid_w do
				lsPrintln('doing ' .. x .. ',' .. y);
	
				statusScreen("(" .. loop_count .. "/" .. num_loops .. ") Planting " .. x .. ", " .. y);
	
				-- Plant
				srClickMouseNoMove(xyPlantOnions[0], xyPlantOnions[1], 0);
				-- lsSleep(delay_time);
				
				-- Move to new location
				if x == grid_w then
					walk_dy = walk_px_y;
					walk_dx = 0;
				else
					walk_dy = 0;
					if y % 2 == 1 then
						walk_dx = walk_px_x;
					else
						walk_dx = -walk_px_x;
					end
				end
				lsPrintln("Moving cntr:" .. xyCenter[0] .. " " .. xyCenter[1] .. " d=" .. walk_dx .. " " .. walk_dy);
				srClickMouseNoMove(xyCenter[0] + walk_dx, xyCenter[1] + walk_dy);
				lsSleep(walk_time);
				
				-- Search for menu
				xyImagePos = nil;
			
				search_idx = 1;
				while not xyImagePos and search_idx <= #search_dx do
					click_x = xyCenter[0] - walk_dx + math.floor(search_dx[search_idx] * pixel_scale);
					click_y = xyCenter[1] - walk_dy + math.floor(search_dy[search_idx] * pixel_scale);
					lsPrintln(' clicking ' .. click_x .. ',' .. click_y);
					srClickMouse(click_x, click_y, 1); -- Right click!
					lsSleep(screen_refresh_time);
					checkBreak();
					srReadScreen();
					xyImagePos = srFindImageInRange(imgOnionBed, click_x - walk_px_x*2, click_y - 42 - walk_px_y*2, window_w+walk_px_x*4, window_h+walk_px_y*4);
					if xyImagePos then
						-- found it
						click_x = xyImagePos[0] - 6;
						click_y = xyImagePos[1] + 25;
					else
						-- No menu came up, try elsewhere?
						search_idx = search_idx+1;
					end
				end
				
				if not xyImagePos then
					error ' Failed to bring up onion bed window';
				end
				
				-- Pin
				srClickMouseNoMove(click_x+5, click_y, 1);
				
				-- Move window
				local pp = pinnedPos(x, y);
				drag(click_x, click_y,
					pp[0], pp[1], 0);
				-- lsSleep(delay_time);
				
				checkBreak();
			end
		end
		
		srSetMousePos(200, 200);

		statusScreen("(" .. loop_count .. "/" .. num_loops .. ") Refocusing windows...");
		
		-- Bring windows to front
		for y=grid_h, 1, -1 do
			for x=grid_w, 1, -1 do 
				local rp = refreshPosUp(x, y);
				srClickMouseNoMove(rp[0], rp[1], 0);
				lsSleep(refocus_click_time);
			end
		end
		lsSleep(1000); -- Wait for last window to bring to the foreground before clicking again

		-- Water everything and then harvestable
		do_harvest = nil;
		water_pass_count=0;
		passes_before_harvest = 4;
		while 1 do
			water_pass_count = water_pass_count+1;
			start_time = lsGetTimer();
			for y=1, grid_h do
				for x=1, grid_w do 
					if do_harvest then
						statusScreen("(" .. loop_count .. "/" .. num_loops .. ") Harvesting " .. x .. ", " .. y);
					else
						statusScreen("(" .. loop_count .. "/" .. num_loops .. ") Watering " .. x .. ", " .. y .. " water pass " .. water_pass_count);
					end
					local pp = pinnedPos(x, y);
					local rp = refreshPosDown(x, y);
					while 1 do
						srClickMouseNoMove(rp[0], rp[1], 0);
						lsSleep(screen_refresh_time);
						srReadScreen();
						if not do_harvest then
							local water = srFindImageInRange(imgWaterThese, pp[0], pp[1] - 25, window_w, window_h);
							if water then
								srClickMouseNoMove(water[0] + 5, water[1], 0);
								lsSleep(water_time);
								num_waters = num_waters + 1;
								if num_waters >= num_jugs-1 then
									fillWater(1);
								end
								break;
							end
						end
						local harvest = srFindImageInRange(imgHarvestThese, pp[0], pp[1] - 25, window_w, window_h);
						if harvest then
							if do_harvest then
								-- do the harvest
								srClickMouseNoMove(harvest[0] + 5, harvest[1], 0);
								-- dismiss window
								srClickMouseNoMove(rp[0], rp[1], 1);
								lsSleep(harvest_time);
							end
							-- lsPrintln('Ready for harvest, come back later!');
							break;
						end
						lsSleep(10);
						checkBreak();
						-- try again anyway!  error ' Expected Onion window to have either harvest or water!';
					end
				end
			end
			
			if do_harvest then
				break;
			end

			-- Bring windows to front
			for y=grid_h, 1, -1 do
				for x=grid_w, 1, -1 do 
					local rp = refreshPosUp(x, y);
					srClickMouseNoMove(rp[0], rp[1], 0);
					lsSleep(refocus_click_time);
				end
			end
			lsSleep(1000); -- Wait for last window to bring to the foreground before clicking again
		
			if water_pass_count == passes_before_harvest then
				do_harvest = 1;
			else
				-- Otherwise, wait until 24 seconds has elapsed, and water again
				local time_left = pass_growth_time - (lsGetTimer() - start_time);
				statusScreen("Waiting " .. time_left .. "ms before starting next pass...");
				if (time_left > fill_water_time) and (num_waters > 0) then
					fillWater(1);
				end
				while pass_growth_time - (lsGetTimer() - start_time) > 0 do
					time_left = pass_growth_time - (lsGetTimer() - start_time);
					statusScreen("(" .. loop_count .. "/" .. num_loops .. ") Waiting " .. time_left .. "ms before starting next water pass...");
					lsSleep(100);
					checkBreak();
				end
			end
		end
		
		lsSleep(1000); -- wait for harvested plants to disappear
		
		-- Move back a bit
		if grid_h % 2 == 1 then
			srClickMouseNoMove(xyCenter[0] - walk_px_x*2, xyCenter[1] - walk_px_y);
		else
			srClickMouseNoMove(xyCenter[0] + walk_px_x*2, xyCenter[1] - walk_px_y);
		end
		lsSleep(1000); -- wait to move back
	end
	
	lsPlaySound("Complete.wav");
end
