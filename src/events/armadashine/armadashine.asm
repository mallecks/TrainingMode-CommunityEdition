###################################
## Armada Shine HIJACK INFO ##
###################################

ArmadaShine:
    # Store Stage, CPU, and FDD Toggles
    lwz r3, 0x0(r29)                                    # Send event struct
    mr r4, r26                                          # Send match struct
    li r5, Fox.Ext                                      # Use fox
    li r6, -1                                           # Use chosen Stage
    load r7, EventOSD_ArmadaShine
    li r8, 0                                            # Use Sopo bool
    bl InitializeMatch

# STORE THINK FUNCTION
ArmadaShineStoreThink:
    bl ArmadaShineLoad
    mflr r3
    stw r3, 0x44(r26)                                   # on match load

    b exit

##################################
## Armada Shine LOAD FUNCT ##
##################################
ArmadaShineLoad:
    blrl

    backup

    # Schedule Think
    bl ArmadaShineThink
    mflr r3
    li r4, 3                                            # Priority (After EnvCOllision)
    li r5, 0
    bl CreateEventThinkFunction

    # Remove randall
    lwz r3, StageID_External(r13)
    cmpwi r3, YoshiStory
    bne LedgedashLoad_SkipRemoveRandall
    # Get randall's map_gobj
    li r3, 2                                            # randalls map_gobj is 2
    branchl r12, Stage_map_gobj_Load
    branchl r12, Stage_Destroy_map_gobj
LedgedashLoad_SkipRemoveRandall:

    b ArmadaShineThink_Exit

###################################
## Armada Shine THINK FUNCT ##
###################################

ArmadaShineThink:
    blrl

    # Registers
    .set REG_EventConstants, 25
    .set REG_MenuData, 26
    .set REG_EventData, 31
    .set REG_P1Data, 27
    .set REG_P1GObj, 28
    .set REG_P2Data, 29
    .set REG_P2GObj, 30

    # Event Data Offsets
    .set EventState, 0x0
    .set EventState_Hitstun, 0x0
    .set EventState_Falling, 0x1
    .set EventState_RecoverStart, 0x2
    .set EventState_RecoverEnd, 0x3
    .set EventState_Reset, 0x4
    .set Timer, 0x1

    # Constants
    .set ResetTimer, 80
    .set QuickResetTimer, 30
    .set PercentLo, 0
    .set PercentHi, 60

    backup

    # INIT FUNCTION VARIABLES
    lwz REG_EventData, 0x2c(r3)                         # backup data pointer in r31

    # Get Player Pointers
    bl GetAllPlayerPointers
    mr REG_P1GObj, r3
    mr REG_P1Data, r4
    mr REG_P2GObj, r5
    mr REG_P2Data, r6

    # Get Menu and Constants Pointers
    lwz REG_MenuData, REG_EventData_REG_MenuDataPointer(REG_EventData)
    bl ArmadaShineThink_Constants
    mflr REG_EventConstants

    bl StoreCPUTypeAndZeroInputs

    # ON FIRST FRAME
    bl CheckIfFirstFrame
    cmpwi r3, 0x0
    beq ArmadaShineThink_Start
    # Init Positions
    mr r3, REG_P1GObj
    mr r4, REG_P2GObj
    bl ArmadaShine_InitializePositions
    # Clear Inputs
    bl RemoveFirstFrameInputs
    # Save State
    addi r3, REG_EventData, EventData_SaveStateStruct
    li r4, 1                                            # Override failsafe code
    bl SaveState_Save
    # Init State
    li r3, EventState_Hitstun
    stb r3, EventState(REG_EventData)

ArmadaShineThink_Start:
    # Reset if anyone died
    bl IsAnyoneDead
    cmpwi r3, 0
    bne ArmadaShineThink_Restore

    # DPad left to instant reset
    lbz r3, 0x0618(REG_P1Data)
    bl GetInputStruct
    lwz r4, InputStruct_InstantButtons(r3)
    rlwinm. r0, r4, 0, 31, 31
    bne ArmadaShineThink_Restore

ArmadaShineThink_GroundCheck:
    # If P2 is grounded, reset quick
    lwz r3, 0xE0(REG_P2Data)
    cmpwi r3, 0
    beq ArmadaShineThink_GroundCheck_OnGround
    # If P2 is grabbing a cliff, reset quick
    lwz r3, 0x10(REG_P2Data)
    cmpwi r3, ASID_CliffCatch
    beq ArmadaShineThink_GroundCheck_OnGround
    b ArmadaShineThink_GroundCheckSkip

ArmadaShineThink_GroundCheck_OnGround:
    # Check if timer was set
    lbz r3, Timer(REG_EventData)
    cmpwi r3, QuickResetTimer
    ble ArmadaShineThink_GroundCheckSkip
    # Set timer
    li r3, QuickResetTimer
    stb r3, Timer(REG_EventData)
    # Change State
    li r3, EventState_Reset
    stb r3, EventState(REG_EventData)

ArmadaShineThink_GroundCheckSkip:
    # Switch Case
    lbz r3, EventState(REG_EventData)
    cmpwi r3, EventState_Hitstun
    beq ArmadaShineThink_Hitstun
    cmpwi r3, EventState_Falling
    beq ArmadaShineThink_Falling
    cmpwi r3, EventState_RecoverStart
    beq ArmadaShineThink_RecoverStart
    cmpwi r3, EventState_RecoverEnd
    beq ArmadaShineThink_RecoverEnd
    cmpwi r3, EventState_Reset
    beq ArmadaShineThink_Reset
    b ArmadaShineThink_Exit

ArmadaShineThink_Hitstun:
    # Check if still in hitstun
    lbz r3, 0x221C(REG_P2Data)
    rlwinm. r3, r3, 0, 30, 30
    bne ArmadaShineThink_Hitstun_Exit
    # Change Event State
    li r3, EventState_Falling
    stb r3, EventState(REG_EventData)
    # Run Next State Code
    b ArmadaShineThink_Falling

ArmadaShineThink_Hitstun_Exit:
    # Always L-Cancel
    li r3, 0
    stb r3, 0x67F(REG_P1Data)
    b ArmadaShineThink_Exit

ArmadaShineThink_Falling:
    .set FirefoxRadius, 80
    .set FirefoxChance, 8
    # Get distance from ledge
    addi r3, REG_P2Data, 0xB0
    addi r4, REG_P2Data, 0x1ADC
    bl GetDistance
    stfs f1, 0x80(sp)
    # Fox travels approx 82 Mm during firefox, so ensure he is at least this far
    li r3, FirefoxRadius
    bl IntToFloat
    lfs f2, 0x80(sp)
    fcmpo cr0, f2, f1
    bge ArmadaShineThink_Falling_EnterFirefox
    # Random chance to firefox
    li r3, FirefoxChance
    branchl r12, HSD_Randi
    cmpwi r3, 0
    beq ArmadaShineThink_Falling_EnterFirefox
    b ArmadaShineThink_Exit

ArmadaShineThink_Falling_EnterFirefox:
    # Enter Firefox
    li r3, 127
    stb r3, CPU_AnalogY(REG_P2Data)
    li r3, PAD_BUTTON_B
    stw r3, CPU_HeldButtons(REG_P2Data)
    # Change Event State
    li r3, EventState_RecoverStart
    stb r3, EventState(REG_EventData)
    # Exit
    b ArmadaShineThink_Exit

ArmadaShineThink_RecoverStart:
    .set RestartTimer, 30
    .set FirefoxHoldFrames, 43

ArmadaShineThink_RecoverStart_CheckIfDone:
    # Check if no longer in SpecialHiStart
    lwz r3, 0x10(REG_P2Data)
    cmpwi r3, 354
    beq ArmadaShineThink_RecoverStart_CheckIfDoneSkip
    # Start restart timer
    lwz r3, 0x4(REG_P1Data)
    cmpwi r3, Fox.Int
    bne ArmadaShineThink_RecoverStart_NotFox
    li r3, RestartTimer
    b ArmadaShineThink_RecoverStart_StoreRestartTimer

ArmadaShineThink_RecoverStart_NotFox:
    li r3, RestartTimer+60

ArmadaShineThink_RecoverStart_StoreRestartTimer:
    stb r3, Timer(REG_EventData)
    # Change Event State
    li r3, EventState_RecoverEnd
    stb r3, EventState(REG_EventData)
    # Run Next State Code
    b ArmadaShineThink_RecoverEnd

ArmadaShineThink_RecoverStart_CheckIfDoneSkip:
    /*
    # Wait until last frame of firefox
    lhz r3, TM_FramesinCurrentAS(REG_P2Data)
    cmpwi r3, FirefoxHoldFrames-2
    beq ArmadaShineThink_RecoverStart_InputAngle
    # Input Up
    li r3, 127
    stb r3, CPU_AnalogY(REG_P2Data)
    b ArmadaShineThink_RecoverStart_Exit
    */

ArmadaShineThink_RecoverStart_InputAngle:
    # Backup f28-f31
    stfs f29, 0xB0(sp)
    stfs f30, 0xB4(sp)
    stfs f31, 0xB8(sp)
    stfs f28, 0xBC(sp)
    stfs f27, 0xC0(sp)

    # Hold towards ledge
    # Get Angle Between Fox and Ledge
    addi r3, REG_P2Data, 0xB0
    addi r4, REG_P2Data, 0x1ADC
    bl GetAngleBetweenPoints

    # Convert this to an input
    .set REG_arctan, 31
    .set REG_XComp, 30
    .set REG_YComp, 31
    .set REG_127, 29
    # Backup arctan
    fmr REG_arctan, f1
    # Get 127 as a float
    li r3, 127
    bl IntToFloat
    fmr REG_127, f1
    # Get X Component
    fmr f1, REG_arctan                                  # angle in radians
    branchl r12, cos
    fmr REG_XComp, f1
    # Get Y Component
    fmr f1, REG_arctan                                  # angle in radians
    branchl r12, sin
    fmr REG_YComp, f1
    # Get X input
    fmuls f1, REG_XComp, REG_127
    fctiwz f1, f1,
    stfd f1, 0x80(sp)
    lwz r3, 0x84(sp)
    stb r3, 0x1A8C(REG_P2Data)
    # Get Y input
    fmuls f1, REG_YComp, REG_127
    fctiwz f1, f1,
    stfd f1, 0x80(sp)
    lwz r3, 0x84(sp)
    stb r3, 0x1A8D(REG_P2Data)

    .set REG_XPerFrame, 29
    .set REG_YPerFrame, 28
    .set REG_CurrXPos, 27
    .set REG_CurrYPos, 26
    .set REG_ECBStruct, 20
    .set REG_ECBBoneStruct, 21
    .set REG_LoopCount, 22
    .set FirefoxFrames, 30
    .set RandomAngleRange, 20

    # Get Per Frame Velocity
    mr r3, REG_P2Data
    branchl r12, 0x800a17e4
    fmr REG_XComp, f1
    mr r3, REG_P2Data
    branchl r12, 0x800a1874
    fmr REG_YComp, f1
    # Get atan2
    fmr f1, REG_YComp
    lfs f2, 0x2C(REG_P2Data)
    fmuls f2, f2, REG_XComp
    branchl r12, 0x80022c30
    fmr REG_arctan, f1
    # Get XComp
    fmr f1, REG_arctan
    branchl r12, 0x80326240
    fmr REG_XComp, f1
    fmr f1, REG_arctan
    branchl r12, 0x803263d4
    fmr REG_YComp, f1
    # Get Firefox distance per frame
    lwz r3, 0x02D4(REG_P2Data)
    lfs f1, 0x0074(r3)
    lfs f0, 0x002C(REG_P2Data)
    fmuls f1, f1, REG_XComp
    fmuls REG_XPerFrame, f1, f0
    lfs f1, 0x0074(r3)
    fmuls REG_YPerFrame, f1, REG_YComp
    # Create an ECB struct on the stack
    subi sp, sp, 0x1d0
    addi REG_ECBBoneStruct, sp, 0xC
    addi REG_ECBStruct, sp, 0x24
    mr r3, REG_ECBStruct
    branchl r12, 0x80041ee4
    # Create ECB Bone struct
    /*
    0x00 = ECB Current Top Y Offset scale * value
    0x04 = ECB Current Bottom Y Offset neg(scale * vlaue)
    0x08 = ECB Current Left X Offset neg(scale * vlaue)
    0x0C = ECB Current Left Y Offset 0
    0x10 = ECB Current Right X Offset scale * value
    0x14 = ECB Current Right Y Offset 0
    */
    # Copy Struct
    mr r3, REG_ECBBoneStruct
    addi r4, REG_EventConstants, ECB_TopY
    li r5, 0x18
    branchl r12, memcpy
    # Place Current XY into struct
    lfs REG_CurrXPos, 0xB0(REG_P2Data)
    lfs REG_CurrYPos, 0xB4(REG_P2Data)
    # Subtract 0.4 to account for the frame of animation left in this state
    lfs f1, FinalAnimYDifference(REG_EventConstants)
    fsubs REG_CurrYPos, REG_CurrYPos, f1
    lfs f1, 0xB8(REG_P2Data)
    stfs f1, 0x24(REG_ECBStruct)
    # Init Loop
    li REG_LoopCount, 0

ArmadaShineThink_RecoverStart_CollisionLoop:
    # Store current position
    stfs REG_CurrXPos, 0x1C(REG_ECBStruct)
    stfs REG_CurrYPos, 0x20(REG_ECBStruct)
    # Check if frame X or greater
    lwz r5, 0x02D4(REG_P2Data)
    lfs f1, 0x70(r5)
    fctiwz f1, f1
    stfd f1, -0x10(sp)
    lwz r3, -0x0C(sp)
    cmpw REG_LoopCount, r3
    blt ArmadaShineThink_RecoverStart_CollisionLoop_SkipDecay

ArmadaShineThink_RecoverStart_CollisionLoop_Decay:
    lfs f1, 0x78(r5)
    fmuls f1, f1, REG_XComp
    lfs f2, 0x002C(REG_P2Data)
    fmuls f1, f1, f2
    fsubs REG_XPerFrame, REG_XPerFrame, f1
    lfs f1, 0x78(r5)
    fmuls f1, f1, REG_YComp
    fsubs REG_YPerFrame, REG_YPerFrame, f1

ArmadaShineThink_RecoverStart_CollisionLoop_SkipDecay:
    # Store next position
    fadds f1, REG_CurrXPos, REG_XPerFrame
    stfs f1, 0x4(REG_ECBStruct)
    fadds f1, REG_CurrYPos, REG_YPerFrame
    stfs f1, 0x8(REG_ECBStruct)
    lfs f1, 0x24(REG_ECBStruct)
    stfs f1, 0xC(REG_ECBStruct)
    mr r3, REG_ECBStruct
    mr r4, REG_ECBBoneStruct
    branchl r12, 0x8004730c
    lfs REG_CurrXPos, 0x4(REG_ECBStruct)
    lfs REG_CurrYPos, 0x8(REG_ECBStruct)
    # Inc Loop
    addi REG_LoopCount, REG_LoopCount, 1
    lwz r5, 0x02D4(REG_P2Data)
    lfs f1, 0x0068(r5)
    fctiwz f1, f1
    stfd f1, -0x10(sp)
    lwz r3, -0x0C(sp)
    cmpw REG_LoopCount, r3
    blt ArmadaShineThink_RecoverStart_CollisionLoop
    # End Loop
    addi sp, sp, 0x1d0

    # Restore f28-f31
    lfs f29, 0xB0(sp)
    lfs f30, 0xB4(sp)
    lfs f31, 0xB8(sp)
    lfs f28, 0xBC(sp)
    lfs f27, 0xC0(sp)

ArmadaShineThink_RecoverStart_Exit:
    b ArmadaShineThink_Exit

ArmadaShineThink_RecoverEnd:
    # If CPU got hit, recover again
    lbz r3, 0x221C(REG_P2Data)
    rlwinm. r3, r3, 0, 30, 30
    beq ArmadaShineThink_Reset
    # Enter Hitstun state
    li r3, EventState_Hitstun
    stb r3, EventState(REG_EventData)
    b ArmadaShineThink_Exit

ArmadaShineThink_Reset:
    # Get timer
    lbz r3, Timer(REG_EventData)
    subi r3, r3, 1
    stb r3, Timer(REG_EventData)
    cmpwi r3, 0
    ble ArmadaShineThink_Restore
    b ArmadaShineThink_Exit

ArmadaShineThink_Restore:
    # Restore State
    addi r3, REG_EventData, EventData_SaveStateStruct
    li r4, 1
    bl SaveState_Load
    # Init Positions Again
    mr r3, REG_P1GObj
    mr r4, REG_P2GObj
    bl ArmadaShine_InitializePositions
    # Reset Variables
    li r3, 0
    stb r3, EventState(REG_EventData)
    stb r3, Timer(REG_EventData)

ArmadaShineThink_Exit:
    restore
    blr

ArmadaShineThink_Constants:
    blrl

    .set ECB_TopY, 0x0                                  # scale * value
    .set ECB_BottomY, 0x4                               # neg(scale * vlaue)
    .set ECB_LeftX, 0x8                                 # neg(scale * vlaue)
    .set ECB_LeftY, 0xC                                 # 0
    .set ECB_RightX, 0x10                               # scale * value
    .set ECB_RightY, 0x14                               # 0
    .set FinalAnimYDifference, 0x18
    .float 9
    .float 2.5
    .float -3.3
    .float 5.7
    .float 3.3
    .float 5.7
    .float 0.4

ArmadaShine_InitializePositions:
    backup

    .set LedgeSide, 20

    # Constants
    .set ArmadaShine_P1X, 15
    .set ArmadaShine_P1Y, 6
    .set ArmadaShine_P2X, 12
    .set ArmadaShine_P2Y, 6
    .set HitlagFrames, 12

    # Get random side
    li r3, 2
    branchl r12, HSD_Randi
    # Backup Ledge Side
    mr LedgeSide, r3

    # Change Facing Directions
    cmpwi LedgeSide, 0x0
    beq ArmadaShine_InitializePositions_GetLeftLedgeID

ArmadaShine_InitializePositions_GetRightLedgeID:
    # Change Facing Direction
    li r3, -1
    bl IntToFloat
    stfs f1, 0x2C(REG_P1Data)
    li r3, -1
    bl IntToFloat
    stfs f1, 0x2C(REG_P2Data)
    b ArmadaShine_InitializePositions_DirectionChangeEnd

ArmadaShine_InitializePositions_GetLeftLedgeID:
    # Change Facing Direction
    li r3, 1
    bl IntToFloat
    stfs f1, 0x2C(REG_P1Data)
    li r3, 1
    bl IntToFloat
    stfs f1, 0x2C(REG_P2Data)

ArmadaShine_InitializePositions_DirectionChangeEnd:
    # Get Ledge Coordinates
    mr r3, LedgeSide
    addi r4, sp, 0x80
    bl GetLedgeCoordinates

    # Move P1
    li r3, ArmadaShine_P1X
    bl IntToFloat
    lfs f2, 0x80(sp)
    lfs f3, 0x2C(REG_P1Data)
    fmadds f1, f1, f3, f2
    stfs f1, 0xB0(REG_P1Data)
    li r3, ArmadaShine_P1Y
    bl IntToFloat
    lfs f2, 0x84(sp)
    fadds f1, f1, f2
    stfs f1, 0xB4(REG_P1Data)
    mr r3, REG_P1GObj
    bl UpdatePosition
    # Move P2
    li r3, ArmadaShine_P2X
    bl IntToFloat
    lfs f2, 0x80(sp)
    lfs f3, 0x2C(REG_P2Data)
    fmadds f1, f1, f3, f2
    stfs f1, 0xB0(REG_P2Data)
    li r3, ArmadaShine_P2Y
    bl IntToFloat
    lfs f2, 0x84(sp)
    fadds f1, f1, f2
    stfs f1, 0xB4(REG_P2Data)
    mr r3, REG_P2GObj
    bl UpdatePosition
    # P1 enters Bair
    mr r3, REG_P1GObj
    li r4, ASID_AttackAirB
    branchl r12, 0x8008cfac
    # Fastforward to frame 7
    li r3, 7
    bl IntToFloat
    mr r3, REG_P1GObj
    lfs f2, -0x67D8(rtoc)
    lfs f3, -0x67E4(rtoc)
    branchl r12, 0x8006ebe8
    li r3, 7
    bl IntToFloat
    stfs f1, 0x894(REG_P1Data)
    li r3, 0
    stw r3, 0x3E4(REG_P1Data)
    mr r3, REG_P1GObj
    branchl r12, 0x80073354
    # Update Animation
    mr r3, REG_P1GObj
    branchl r12, 0x8006e9b4
    # Remove all hitboxes
    mr r3, REG_P1GObj
    branchl r12, 0x8007aff8
    # Stop subaction script from being updated
    li r3, 0
    stw r3, 0x3EC(REG_P1Data)
    # Update Camera
    mr r3, REG_P1GObj
    bl UpdateCameraBox

    # P2 enters DamageFlyN
    mr r3, REG_P2GObj
    li r4, ASID_DamageFlyN
    li r5, 0x40
    li r6, 0
    lfs f1, -0x750C(rtoc)
    lfs f2, -0x7508(rtoc)
    lfs f3, -0x750C(rtoc)
    branchl r12, ActionStateChange
    # Update Animation
    mr r3, REG_P2GObj
    branchl r12, 0x8006e9b4
    # Remove Jump
    lwz r3, 0x168(REG_P2Data)
    stb r3, 0x1968(REG_P2Data)
    # Update Camera
    mr r3, REG_P2GObj
    bl UpdateCameraBox

    .set AngleLo, 45
    .set AngleHi, 60
    .set MagLo, 106
    .set MagHi, 120
    # Enter into knockback
    mr r3, REG_P2GObj
    li r4, AngleLo
    li r5, AngleHi
    li r6, MagLo
    li r7, MagHi
    bl EnterKnockback

    # Give 7 Frames of Hitlag to Each
    li r3, HitlagFrames
    bl IntToFloat
    stfs f1, 0x195C(REG_P1Data)
    lbz r0, 0x221A(REG_P1Data)
    li r3, 1
    rlwimi r0, r3, 5, 26, 26
    stb r0, 0x221A(REG_P1Data)
    lbz r0, 0x2219(REG_P1Data)
    li r3, 1
    rlwimi r0, r3, 2, 29, 29
    stb r0, 0x2219(REG_P1Data)
    li r3, HitlagFrames
    bl IntToFloat
    stfs f1, 0x195C(REG_P2Data)
    lbz r0, 0x221A(REG_P2Data)
    li r3, 1
    rlwimi r0, r3, 5, 26, 26
    stb r0, 0x221A(REG_P2Data)
    lbz r0, 0x2219(REG_P2Data)
    li r3, 1
    rlwimi r0, r3, 2, 29, 29
    stb r0, 0x2219(REG_P2Data)

    # Random percent
    li r3, PercentHi-PercentLo
    branchl r12, HSD_Randi
    addi r4, r3, PercentLo
    lbz r3, 0xC(REG_P2Data)
    branchl r12, PlayerBlock_SetDamage

ArmadaShine_InitializePositions_Exit:
    restore
    blr
