#########################
## Waveshine SDI HIJACK INFO ##
#########################

WaveshineSDI:
    # Store Stage, CPU, and FDD Toggles
    lwz r3, 0x0(r29)                                    # Send event struct
    mr r4, r26                                          # Send match struct
    li r5, Fox.Ext                                      # Use chosen CPU
    li r6, FinalDestination                             # Use chosen Stage
    load r7, EventOSD_WaveshineSDI
    li r8, 1                                            # Use Sopo bool
    bl InitializeMatch

# STORE THINK FUNCTION
WaveshineSDIStoreThink:
    bl WaveshineSDILoad
    mflr r3
    stw r3, 0x44(r26)                                   # on match load

    b exit

########################
## Waveshine SDI LOAD FUNCT ##
########################
WaveshineSDILoad:
    blrl

    backup

    # Schedule Think
    bl WaveshineSDIThink
    mflr r3
    li r4, 3                                            # Priority (After Interrupt)
    li r5, 0
    bl CreateEventThinkFunction

    /*
    # Make Long Destination
    # Get Stage DAT Pointer
    load r3, 0x80432290
    lwz r3, 0x10(r3)
    lwz r6, 0x4(r3)
    lis r3, 0x4040
    li r5, 0x0
    ori r4, r5, 0xF488
    stwx r3, r6, r4
    ori r4, r5, 0xF4CC
    stwx r3, r6, r4
    ori r4, r5, 0xF4D0
    stwx r3, r6, r4
    ori r4, r5, 0xF590
    stwx r3, r6, r4
    lis r4, 0x1
    ori r4, r4, 0x88
    stwx r3, r6, r4
    lis r4, 0x1
    ori r4, r4, 0x608
    stwx r3, r6, r4
    lis r3, 0x4248
    ori r4, r5, 0xF4D8
    stwx r3, r6, r4
    lis r4, 0x5
    ori r4, r4, 0x1B90
    stwx r5, r6, r4
    lis r5, 0x5
    lis r3, 0xC3AA
    ori r3, r3, 0x91EC
    ori r4, r5, 0x1F20
    stwx r3, r6, r4
    lis r3, 0x43AA
    ori r3, r3, 0x91EC
    ori r4, r5, 0x1F60
    stwx r3, r6, r4
    lis r3, 0xC3D0
    ori r3, r3, 0x91EC
    ori r4, r5, 0x1FA0
    stwx r3, r6, r4
    lis r3, 0x43D0
    ori r3, r3, 0x91EC
    ori r4, r5, 0x1FE0
    stwx r3, r6, r4
    */

    b WaveshineSDILoadExit

#########################
## Waveshine SDI THINK FUNCT ##
#########################

WaveshineSDIThink:
    blrl

    .set EventData, 31
    .set P1Data, 27
    .set P1GObj, 28
    .set P2Data, 29
    .set P2GObj, 30

    backup

    # INIT FUNCTION VARIABLES
    lwz EventData, 0x2c(r3)                             # backup data pointer in r31

    bl GetAllPlayerPointers
    mr P1GObj, r3
    mr P1Data, r4
    mr P2GObj, r5
    mr P2Data, r6

    bl StoreCPUTypeAndZeroInputs

    # ON FIRST FRAME
    bl CheckIfFirstFrame
    cmpwi r3, 0x0
    beq WaveshineSDIThinkMain

    # Set Frame 1 As Over
    li r3, 0x1
    stb r3, 0x0(r31)
    # Set Facing Directions
    lis r3, 0x3f80
    stw r3, 0x2C(r29)
    lis r3, 0xBf80
    stw r3, 0x2C(r27)
    # Initlize Positions
    bl WaveshineSDI_Floats
    mflr r3
    bl InitializePositions
    # Clear Inputs
    bl RemoveFirstFrameInputs
    # Store Ground As Last Known Position
    lfs f1, 0x00B4(r29)
    stfs f1, 0x0834(r29)
    # Save State
    addi r3, EventData, EventData_SaveStateStruct
    li r4, 1                                            # Override failsafe code
    bl SaveState_Save
    # Set Timer to -60
    li r3, -60
    stw r3, 0x4(r31)

WaveshineSDIThinkMain:

WaveshineSDIThinkSequence:
    # Inc Timer
    lwz r3, 0x4(r31)
    addi r3, r3, 0x1
    stw r3, 0x4(r31)

    # Get Floats
    bl WaveshineSDI_Floats
    mflr r21

    # Check Timer
    cmpwi r3, 0x0
    blt WaveshineSDICheckToReset

    # Check If Edge Of Stage
    lfs f1, 0xB0(r29)                                   # P1 X Coord
    lfs f2, 0x18(r21)                                   # Max X Coord
    fabs f1, f1
    fabs f2, f2
    fcmpo cr0, f1, f2
    blt WaveshineSDISkipBoundaryCheck
    # Freeze Fox If So
    lbz r0, 0x2219(r29)
    li r3, 1
    rlwimi r0, r3, 2, 29, 29
    stb r0, 0x2219(r29)
    lwz r3, 0xC(r31)
    cmpwi r3, 0x0                                       # No Reset Timer Set Yet
    bgt WaveshineSDICheckToReset
    li r3, 60                                           # Set Timer If Not Set Yet
    stw r3, 0xC(r31)
    b WaveshineSDICheckToReset

WaveshineSDISkipBoundaryCheck:
    # Check If Fox Grabbed Marth
    lwz r3, 0x10(r29)
    cmpwi r3, 0xD8
    bne WaveshineSDICheckDrillOrWaveshine
    lwz r3, 0xC(r31)
    cmpwi r3, 0x0
    bgt WaveshineSDICheckDrillOrWaveshine
    li r3, 60
    stw r3, 0xC(r31)

# Check If Drilling or Waveshining
WaveshineSDICheckDrillOrWaveshine:
    lbz r3, 0x8(r31)
    cmpwi r3, 0x1
    bge WaveshineSDIWaveshineThink

# Run Drill Code
WaveshineSDIDrillThink:
    lwz r3, 0x10(r29)

WaveshineSDIDrillThink_CheckToJump:
    cmpwi r3, 0xE
    bne WaveshineSDIDrillThink_CheckToDair
    li r3, 0x400
    stw r3, 0x1A88(r29)
    b WaveshineSDICheckToReset

WaveshineSDIDrillThink_CheckToDair:
    cmpwi r3, 0x19
    bne WaveshineSDI_CheckToFF
    li r3, -127
    stb r3, 0x1A8F(r29)
    b WaveshineSDICheckToReset

WaveshineSDI_CheckToFF:
    # Check If Drilling
    cmpwi r3, 0x45
    bne WaveshineSDICheckToReset
    # Joystick X = 36 * Facing Direction (Drift Forward during drill
    lfs f1, 0x2C(r29)
    fctiwz f1, f1
    stfd f1, 0xF0(sp)
    lwz r4, 0xF4(sp)
    li r3, 36                                           # X Stick
    mullw r3, r3, r4
    stb r3, 0x1A8C(r29)
    # Check If Already FF'ing
    lbz r3, 0x221A(r29)
    rlwinm. r3, r3, 0, 28, 28
    bne WaveshineSDICheckToLCancel
    # Check If Falling
    lfs f2, 0x84(r29)
    lfs f0, -0x76B0(rtoc)
    fcmpo cr0, f2, f0
    bge WaveshineSDICheckToReset
    # Input Down to FF
    li r3, -127
    stb r3, 0x1A8D(r29)                                 # Ananlog Y

WaveshineSDICheckToLCancel:
    # Check If Under 5Mm Above Ground
    lfs f2, 0xB4(r29)
    lfs f0, 0x834(r29)                                  # Last Grounded Y Pos
    fsubs f2, f2, f0                                    # Distance from Floor
    lfs f0, 0x10(r21)                                   # 5 fp
    fcmpo cr0, f2, f0                                   # If less than 5 Mm away, Input L Cancel
    bgt WaveshineSDICheckToReset
    li r3, 0xC0                                         # Hit L
    stw r3, 0x1A88(r29)                                 # Held Buttons
    li r3, 0x1                                          # Set Start Waveshine Flag
    stb r3, 0x8(r31)
    b WaveshineSDICheckToReset

# Run Waveshine Code
WaveshineSDIWaveshineThink:
    lwz r3, 0x10(r29)

    # Shine If In Wait
    cmpwi r3, 0xE
    bne WaveshineSDICheckToJump
    # Check If First Shine Or FollowUp Shine
    lbz r4, 0x8(r31)
    cmpwi r4, 0x2
    beq WaveshineSDIWaveshine_FollowOpponent
    # Input Shine
    li r3, -127
    stb r3, 0x1A8D(r29)
    li r3, 0x200
    stw r3, 0x1A88(r29)
    # Set Flag as Mid-Waveshine
    li r3, 0x2
    stb r3, 0x8(r31)
    # Get JC Timing
    li r3, 3
    branchl r12, HSD_Randi
    stb r3, 0x9(r31)
    b WaveshineSDICheckToReset

# Jump If In Shine Loop
WaveshineSDICheckToJump:
    # Check
    # Check For Shine Loop
    cmpwi r3, 0x169
    bne WaveshineSDICheckToAirdodge
    # Check For JC Frame
    lbz r3, 0x9(r31)                                    # Get JC Timing
    bl IntToFloat
    lfs f2, 0x894(r29)
    fcmpo cr0, f1, f2
    bne WaveshineSDICheckToReset
    # Jump
    li r3, 0x400
    stw r3, 0x1A88(r29)
    b WaveshineSDICheckToReset

# Airdodge If In JumpF
WaveshineSDICheckToAirdodge:
    cmpwi r3, 0x19
    bne WaveshineSDIWaveshine_CheckIfFollowingOpponent
    # Get Random Airdodge Angle
    li r3, 30                                           # 30 Different Angles
    branchl r12, HSD_Randi
    addi r3, r3, 310                                    # Start at 310°
    bl ComboTrainingDecideStickAngle_ConvertAngle
    # Joystick X = X Component * Facing Direction
    lfs f1, 0x2C(r29)
    fctiwz f1, f1
    stfd f1, 0xF0(sp)
    lwz r5, 0xF4(sp)
    mullw r3, r3, r5
    stb r3, 0x1A8C(r29)
    # Joystick Y = Y Component
    stb r4, 0x1A8D(r29)
    # Press L To Wavedash
    li r3, 0xC0
    stw r3, 0x1A88(r29)
    b WaveshineSDICheckToReset

WaveshineSDIWaveshine_CheckIfFollowingOpponent:
    cmpwi r3, 0xf                                       # Check if Walking
    blt WaveshineSDICheckIfInTeeter
    cmpwi r3, 0x11                                      # Check if Walking
    bgt WaveshineSDICheckIfInTeeter
    b WaveshineSDIWaveshine_FollowOpponent

WaveshineSDICheckIfInTeeter:
    cmpwi r3, 0xf5
    bne WaveshineSDICheckToReset
    b WaveshineSDIRestoreState

WaveshineSDIWaveshine_FollowOpponent:
    # Determine Distance From Opponent
    lfs f1, 0xB0(r27)
    lfs f2, 0xB0(r29)
    fsubs f1, f1, f2
    lfs f2, -0x7414(rtoc)                               # 0f
    fcmpo cr0, f1, f2
    bge WaveshineSDIWaveshine_FollowOpponent_FacingRight

WaveshineSDIWaveshine_FollowOpponent_FacingLeft:
    # Check If Close Enough To Shine
    lfs f2, 0x14(r21)
    fneg f2, f2
    fcmpo cr0, f1, f2
    blt WaveshineSDIWaveshine_FollowOpponent_WalkTowards
    b WaveshineSDIWaveshine_FollowOpponent_EnterShine

# b WaveshineSDIWaveshine_FollowOpponent_CheckMarth
WaveshineSDIWaveshine_FollowOpponent_FacingRight:
    lfs f2, 0x14(r21)
    fcmpo cr0, f1, f2
    bgt WaveshineSDIWaveshine_FollowOpponent_WalkTowards
    b WaveshineSDIWaveshine_FollowOpponent_EnterShine

# Check Opponent
WaveshineSDIWaveshine_FollowOpponent_CheckMarth:
    lwz r3, 0x4(r27)
    cmpwi r3, 0x12                                      # Marth
    beq WaveshineSDIWaveshine_FollowOpponent_EnterGrab

WaveshineSDIWaveshine_FollowOpponent_EnterShine:
    # Shine
    li r3, -127
    stb r3, 0x1A8D(r29)
    li r3, 0x200
    stw r3, 0x1A88(r29)
    # Get JC Timing
    li r3, 3
    branchl r12, HSD_Randi
    stb r3, 0x9(r31)
    b WaveshineSDICheckToReset

WaveshineSDIWaveshine_FollowOpponent_EnterGrab:
    li r3, 0x1C0
    stw r3, 0x1A88(r29)
    b WaveshineSDICheckToReset

WaveshineSDIWaveshine_FollowOpponent_WalkTowards:
    # Walk Towards Opponent
    # Stick Forward
    lfs f1, 0x2C(r29)
    fctiwz f2, f1
    stfd f2, 0xF0(sp)
    lwz r4, 0xF4(sp)
    li r3, 127                                          # X Stick
    mullw r3, r3, r4
    stb r3, 0x1A8C(r29)
    # Override Analog Smash Counter So Always Walking (Set Facing As Prev X Input)
    stfs f1, 0x620(r29)
    b WaveshineSDICheckToReset

    # Initiate Reset Timer
    li r3, 120
    stw r3, 0xC(r31)

# Check To Reset
WaveshineSDICheckToReset:
    lwz r3, 0xC(r31)                                    # get timer #Get Timer
    cmpwi r3, 0x0                                       # No Reset Timer Set Yet
    ble WaveshineSDIThinkExit
    # Dec Timer
    subi r3, r3, 0x1
    stw r3, 0xC(r31)                                    # store timer
    cmpwi r3, 0x0                                       # Check if 0 now
    bne WaveshineSDIThinkExit                           # Exit If Not

WaveshineSDIRestoreState:
    # Invert Facing Directions
    lwz r4, 0x10(r31)
    lwz r5, 0x18(r31)
    lfs f1, 0x2C(r4)
    fneg f1, f1
    stfs f1, 0x2C(r4)
    lfs f1, 0x2C(r5)
    fneg f1, f1
    stfs f1, 0x2C(r5)
    # Invert X Positions
    lfs f1, 0xB0(r4)
    fneg f1, f1
    stfs f1, 0xB0(r4)
    lfs f1, 0xB0(r5)
    fneg f1, f1
    stfs f1, 0xB0(r5)
    # Restore State
    addi r3, EventData, EventData_SaveStateStruct
    bl SaveState_Load
    # Reset Timer
    li r3, 60
    branchl r12, HSD_Randi
    li r4, 0
    sub r3, r4, r3
    stw r3, 0x4(r31)
    # Reset Mid-Waveshine Flag
    li r3, 0x0
    stb r3, 0x8(r31)

WaveshineSDIThinkExit:
    restore
    blr

#################################

WaveshineSDI_Floats:
    blrl
    .long 0xC28C0000                                    # P1 X Position
    .long 0xc2982e6c                                    # P2 X Position
    .long 0x38d1b717                                    # P1 Y Position
    .long 0x38d1b717                                    # FD Floor Y Coord
    .long 0x40A00000                                    # 5fp
    .long 0x40F00000                                    # Distance From Opponent to Waveshine
    .long 0x42A00000                                    # X Coord To Stop

#################################

WaveshineSDILoadExit:
    restore
    blr

##################################################
