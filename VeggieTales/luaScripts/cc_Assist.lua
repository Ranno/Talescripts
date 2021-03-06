-- cc-assist.lua v1.2 -- by Makazi, revised by Tallow
--
-- Provides a control interface for running many charcoal hearths or
-- ovens simultaneously.
--

assert(loadfile("luaScripts/common.inc"))();

askText = singleLine([[
  CC Assist v1.2 (by Makazi, revised by Tallow) --
  Provides a control interface for running many charcoal hearths or
  ovens simultaneously. Make sure the VT window is in the TOP-RIGHT
  corner of the screen.
]]);

wmText = "Tap control on Charcoal Hearths or Ovens to open and pin.";

click_delay = 0;

buttons = {
  {
    name = "Begin",
    buttonPos = makePoint(10, 110),
    buttonSize = 270,
    image = "mm_Begin.png",
    offset = makePoint(20, 10)
  },
  {
    name = "Wood",
    buttonPos = makePoint(10, 166),
    buttonSize = 130,
    image = "mm_Wood.png",
    offset = makePoint(20-4, 30-2)
  },
  {
    name = "Water",
    buttonPos = makePoint(150, 166),
    buttonSize = 130,
    image = "mm_Water.png",
    offset = makePoint(20-5, 30-2)
  },
  {
    name = "Closed",
    buttonPos = makePoint(10, 215),
    buttonSize = 80,
    image = "mm_Vent.png",
    offset = makePoint(15-9, 30-2)
  },
  {
    name = "Open",
    buttonPos = makePoint(105, 215),
    buttonSize = 80,
    image = "mm_Vent.png",
    offset = makePoint(40-9, 30-2)
  },
  {
    name = "Full",
    buttonPos = makePoint(200, 215),
    buttonSize = 80,
    image = "mm_Vent.png",
    offset = makePoint(65-9, 30-2)
  }
};

function doit()
  askForWindow(askText);
  windowManager("Charcoal Setup", wmText);
  unpinOnExit(ccMenu);
end

function ccMenu()
  while 1 do
    for i=1, #buttons do
      if showButton(buttons[i]) then
	runCommand(buttons[i]);
      end
    end
    statusScreen("CC Control Center", 0x00d000ff);
  end
end

function showButton(button)
  return lsButtonText(button.buttonPos[0], button.buttonPos[1],
		      0, button.buttonSize, 0xFFFFFFff, button.name)
end

function runCommand(button)
  clickAllImages(button.image, button.offset[0], button.offset[1]);
end

