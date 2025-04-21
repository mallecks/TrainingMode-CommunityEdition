#########################
## Attack On Shield HIJACK INFO ##
#########################

AttackOnShield:
    # Store Stage, CPU, and FDD Toggles
    lwz r3, 0x0(r29)                                    # Send event struct
    mr r4, r26                                          # Send match struct
    li r5, -1                                           # Use chosen CPU
    li r6, FinalDestination                             # Use SSS Stage
    load r7, EventOSD_AttackOnShield
    li r8, 0                                            # Use Sopo bool
    bl InitializeMatch

    # STORE THINK FUNCTION
    bl AttackOnShieldLoad
    mflr r3
    stw r3, 0x44(r26)                                   # on match load

    b exit

########################
## Attack On Shield LOAD FUNCT ##
########################
AttackOnShieldLoad:
    blrl

    backup

    # Schedule Think
    bl AttackOnShieldThink
    mflr r3
    li r4, 3                                            # Priority (After Interrupt)
    bl AttackOnShieldWindowInfo
    mflr r5
    bl AttackOnShieldWindowText
    mflr r6
    bl CreateEventThinkFunction

    b AttackOnShieldLoadExit

#########################
## Attack On Shield THINK FUNCT ##
#########################

    # Registers
    .set MenuData, 26
    .set EventData, 31
    .set P1Data, 27
    .set P1GObj, 28
    .set P2Data, 29
    .set P2GObj, 30

    .set firstFrameFlag, 0x0
    .set timer, 0x4
    .set OoSOption, MenuData_OptionMenuMemory+0x2 + 0x0
    .set OoSOptionToggled, MenuData_OptionMenuToggled + 0x0

AttackOnShieldThink:
    blrl
    backup

    # INIT FUNCTION VARIABLES
    lwz EventData, 0x2c(r3)                             # backup data pointer in r31
    lwz MenuData, EventData_MenuDataPointer(EventData)

    bl GetAllPlayerPointers
    mr P1GObj, r3
    mr P1Data, r4
    mr P2GObj, r5
    mr P2Data, r6

    bl StoreCPUTypeAndZeroInputs

    # ON FIRST FRAME
    bl CheckIfFirstFrame
    cmpwi r3, 0x0
    beq AttackOnShieldThinkMain
    # Set Frame 1 As Over
    li r3, 0x1
    stb r3, 0x0(r31)
    bl AttackOnShield_Floats
    mflr r3
    bl InitializePositions
    # Clear Inputs
    bl RemoveFirstFrameInputs
    # Save State
    addi r3, EventData, EventData_SaveStateStruct
    li r4, 1                                            # Override failsafe code
    bl SaveState_Save

AttackOnShieldThinkMain:
    bl GiveFullShields

    # Reset If Anyone Dies
    bl IsAnyoneDead
    cmpwi r3, 0x0
    bne AttackOnShieldRestoreState

AttackOnShieldThinkSequence:
    lbz r3, OoSOptionToggled(MenuData)
    cmpwi r3, 0
    beq AttackOnShieldNoOptionToggled
    # Clear Last AS So CPU Doesnt Act Immediately
    li r3, 0
    sth r3, TM_OneASAgo(r29)

AttackOnShieldNoOptionToggled:
    # Get Floats
    bl AttackOnShield_Floats
    mflr r21
    # Get Frames as Int
    lfs f1, 0x894(r29)
    fctiwz f1, f1
    stfd f1, 0xF0(sp)
    lwz r22, 0xF4(sp)

    # Check If Perfroming OoS Option
    lwz r3, 0x4(r31)
    cmpwi r3, 0x0
    ble AttackOnShieldShieldWait
    # Branch To OoSThink
    lbz r3, OoSOption(MenuData)
    cmpwi r3, 0x1
    beq AttackOnShieldNairThink
    cmpwi r3, 0x2
    beq AttackOnShieldUpBThink
    cmpwi r3, 0x3
    beq AttackOnShieldUpSmashThink
    cmpwi r3, 0x4
    beq AttackOnShieldShineThink
    cmpwi r3, 0x7
    beq AttackOnShieldWavedashThink
    b AttackOnShieldShieldWait

AttackOnShieldNairThink:
    lwz r3, 0x10(r29)
    cmpwi r3, 0x19
    bne AttackOnShieldCheckToReset
    # Input Nair
    li r3, 0x100
    stw r3, 0x1A88(r29)
    b AttackOnShieldCheckToReset

AttackOnShieldUpBThink:
    lwz r3, 0x10(r29)
    cmpwi r3, 0x18
    bne AttackOnShieldCheckToReset
    li r3, 127
    stb r3, 0x1A8D(r29)                                 # Press Up
    li r3, 0x200
    stw r3, 0x1A88(r29)                                 # Press B
    b AttackOnShieldCheckToReset

AttackOnShieldUpSmashThink:
    lwz r3, 0x10(r29)
    cmpwi r3, 0x18
    bne AttackOnShieldCheckToReset
    li r3, 127
    stb r3, 0x1A8D(r29)                                 # Press Up
    li r3, 0x100
    stw r3, 0x1A88(r29)                                 # Press A
    b AttackOnShieldCheckToReset

AttackOnShieldShineThink:
    lwz r3, 0x10(r29)
    cmpwi r3, 0x19
    bne AttackOnShieldCheckToReset
    # Input Shine
    li r3, -127
    stb r3, 0x1A8D(r29)
    li r3, 0x200
    stw r3, 0x1A88(r29)
    b AttackOnShieldCheckToReset

AttackOnShieldWavedashThink:
    lwz r3, 0x10(r29)
    cmpwi r3, 0x19
    bne AttackOnShieldCheckToReset
    # Get Random Airdodge Angle
    li r3, 30                                           # 30 Different Angles
    branchl r12, HSD_Randi
    addi r3, r3, 310                                    # Start at 310°
    bl ComboTrainingDecideStickAngle_ConvertAngle
    mr r20, r3
    # Joystick X = X Component * (OpponentDirection)
    bl GetDirectionInRelationToP1
    mullw r3, r3, r20
    stb r3, 0x1A8C(r29)
    # Joystick Y = Y Component
    stb r4, 0x1A8D(r29)
    # Press L To Wavedash
    li r3, 0xC0
    stw r3, 0x1A88(r29)
    b AttackOnShieldCheckToReset

AttackOnShieldShieldWait:
    # Always Hold L
    li r3, 0xC0                                         # Hit L
    stw r3, 0x1A88(r29)                                 # Held Buttons

    # Check If Got Shield Poked
    # Hitlag
    lbz r3, 0x221A(r29)                                 # Check If in Hitlag
    rlwinm. r3, r3, 0, 26, 26
    beq AttackOnShieldCheckForShieldHit
    # Damage State
    lwz r3, 0x10(r29)
    cmpwi r3, 0x4B
    blt AttackOnShieldCheckForShieldHit
    cmpwi r3, 0x5B
    bgt AttackOnShieldCheckForShieldHit
    # Was Hit, Start Reset Timer
    li r3, 48                                           # Init Timer
    stw r3, 0x4(r31)
    b AttackOnShieldThinkExit

AttackOnShieldCheckForShieldHit:
    # Check If In ShieldWait (0xb3)
    lwz r3, 0x10(r29)
    cmpwi r3, 0xB3
    bne AttackOnShieldCheckToReset
    # Check If Was Just in ShieldStun
    lhz r3, TM_OneASAgo(r29)
    cmpwi r3, 0xB5
    bne AttackOnShieldCheckToReset
    # Input OoS Option
    lbz r3, OoSOption(MenuData)
    cmpwi r3, 0x0
    beq AttackOnShieldInputGrab
    cmpwi r3, 0x1
    beq AttackOnShieldNair
    cmpwi r3, 0x2
    beq AttackOnShieldUpB
    cmpwi r3, 0x3
    beq AttackOnShieldUpSmash
    cmpwi r3, 0x4
    beq AttackOnShieldShine
    cmpwi r3, 0x5
    beq AttackOnShieldSpotdodge
    cmpwi r3, 0x6
    beq AttackOnShieldRoll
    cmpwi r3, 0x7
    beq AttackOnShieldWavedash
    cmpwi r3, 0x8
    beq AttackOnShieldNone

AttackOnShieldInputGrab:
    li r3, 0x1C0
    stw r3, 0x1A88(r29)                                 # Press R+A
    li r3, 48                                           # Init Timer
    stw r3, 0x4(r31)
    b AttackOnShieldThinkExit

AttackOnShieldNair:
    li r3, 0xCC0
    stw r3, 0x1A88(r29)                                 # Press X/Y
    li r3, 48                                           # Init Timer
    stw r3, 0x4(r31)
    b AttackOnShieldThinkExit

AttackOnShieldUpB:
    li r3, 127
    stb r3, 0x1A8D(r29)                                 # Press Up
    li r3, 48                                           # Init Timer
    stw r3, 0x4(r31)
    b AttackOnShieldThinkExit

AttackOnShieldUpSmash:
    li r3, 127
    stb r3, 0x1A8D(r29)                                 # Press Up
    li r3, 48                                           # Init Timer
    stw r3, 0x4(r31)
    b AttackOnShieldThinkExit

AttackOnShieldShine:
    li r3, 0xCC0
    stw r3, 0x1A88(r29)                                 # Press X/Y
    li r3, 48                                           # Init Timer
    stw r3, 0x4(r31)
    b AttackOnShieldThinkExit

AttackOnShieldSpotdodge:
    li r3, -127
    stb r3, 0x1A8D(r29)                                 # Press Down
    li r3, 0xC0
    stw r3, 0x1A88(r29)                                 # Press R
    li r3, 48                                           # Init Timer
    stw r3, 0x4(r31)
    b AttackOnShieldThinkExit

AttackOnShieldRoll:
    li r3, 0xC0
    stw r3, 0x1A88(r29)                                 # Press R
    # Push Towards Opponent's Direction
    bl GetDirectionInRelationToP1
    li r4, 127
    mullw r3, r3, r4
    stb r3, 0x1A8C(r29)                                 # Press Away
    li r3, 48                                           # Init Timer
    stw r3, 0x4(r31)
    b AttackOnShieldThinkExit

AttackOnShieldWavedash:
    li r3, 0xCC0
    stw r3, 0x1A88(r29)                                 # Press X/Y
    li r3, 48                                           # Init Timer
    stw r3, 0x4(r31)
    b AttackOnShieldThinkExit

AttackOnShieldNone:
    b AttackOnShieldThinkExit

# Check To Reset
AttackOnShieldCheckToReset:
    lwz r3, 0x4(r31)                                    # get timer #Get Timer
    cmpwi r3, 0x0                                       # Check if >0
    ble AttackOnShieldThinkExit
    # Dec Timer
    subi r3, r3, 0x1
    stw r3, 0x4(r31)                                    # store timer
    cmpwi r3, 0x0                                       # Check if 0 now
    bne AttackOnShieldThinkExit                         # Exit If Not

    # Randomize P1's X Coord
    # Get Random X Coord
    lbz r23, 0x10(r21)                                  # Starting X Coord
    lbz r24, 0x11(r21)                                  # Furthest X Coord
    sub r3, r24, r23                                    # Get Range
    branchl r12, HSD_Randi                              # Get Random Number in Between
    add r3, r3, r23                                     # Add to Starting Coord
    # Cast to Float
    bl IntToFloat
    lwz r3, 0x10(r31)                                   # P1 Backup
    stfs f1, 0xB0(r3)                                   # P1 Backup X Pos
    li r3, 0x1                                          # Opposing Sides of Stage
    bl Randomize_LeftorRightSide

AttackOnShieldRestoreState:
    # Restore State
    addi r3, EventData, EventData_SaveStateStruct
    bl SaveState_Load
    b AttackOnShieldThinkExit

AttackOnShieldThinkExit:
    mr r3, MenuData
    bl ClearToggledOptions
    restore
    blr

#################################

AttackOnShield_Floats:
    blrl
    .long 0xC1A00000                                    # P1 X Position
    .long 0x41A00000                                    # P2 X Position
    .long 0x38d1b717                                    # FD Floor Y Coord
    .long 0x38d1b717                                    # FD Floor Y Coord
    .long 0x14460000                                    # P1 X Rand Pos Range

#################################

AttackOnShieldWindowInfo:
    blrl
# amount of options, amount of options in each window

    .long 0x0008FFFF                                    # 1 window, OoS Option has 10 options

####################################################

AttackOnShieldWindowText:
    blrl

################
## OoS Option ##
################

    # Window Title = OoS Option
    .long 0x4f6f5320
    .long 0x4f707469
    .long 0x6f6e0000

    # Option 1 = Grab
    .long 0x47726162
    .long 0x00000000

    # Option 2 = Nair
    .long 0x4e616972
    .long 0x00000000

    # Option 3 = Up B
    .long 0x55702042
    .long 0x00000000

    # Option 5 = Up Smash
    .long 0x55702d53
    .long 0x6d617368
    .long 0x00000000

    # Option 6 = Shine
    .long 0x5368696e
    .long 0x65000000

    # Option 7 = Spotdodge
    .long 0x53706f74
    .long 0x646f6467
    .long 0x65000000

    # Option 8 = Roll Away
    .long 0x526f6c6c
    .long 0x20417761
    .long 0x79000000

    # Option 9 = Wavedash Away
    .long 0x57617665
    .long 0x64617368
    .long 0x20417761
    .long 0x79000000

    # Option 10 = None
    .long 0x4E6F6E65
    .long 0x00000000

AttackOnShieldLoadExit:
    restore
    blr

################################################################################
