###########################
## Escape Sheik HIJACK INFO ##
###########################

EscapeSheik:
    # Store Stage, CPU, and FDD Toggles
    lwz r3, 0x0(r29)                                    # Send event struct
    mr r4, r26                                          # Send match struct
    li r5, Sheik.Ext
    li r6, FinalDestination                             # Use chosen Stage
    load r7, EventOSD_EscapeSheik
    li r8, 1                                            # Use Sopo bool
    bl InitializeMatch

# STORE THINK FUNCTION
EscapeSheikStoreThink:
    bl EscapeSheikLoad
    mflr r3
    stw r3, 0x44(r26)                                   # on match load

    b exit

##################################
## Escape Sheik LOAD FUNCT ##
##################################
EscapeSheikLoad:
    blrl

    backup

    # Schedule Think
    bl EscapeSheikThink
    mflr r3
    li r4, 3                                            # Priority (After EnvCOllision)
    li r5, 0
    bl CreateEventThinkFunction
    b EscapeSheikThink_Exit

###################################
## Escape Sheik THINK FUNCT ##
###################################

EscapeSheikThink:
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
    .set EventState_ThrowDelay, 0x0
    .set EventState_ThrowEndlag, 0x1
    .set EventState_Chase, 0x2
    .set EventState_Jab2, 0x3
    .set EventState_Reset, 0x4
    .set Timer, 0x1
    .set ThrowTimer, 0x2
    .set JabFrame, 0x4
    .set isJabTwice, 0x5
    .set Jab2Frame, 0x6
    .set Jab2Timer, 0x7
    .set isDisplayedTiming, 0x8

    # Constants
    .set ResetTimer, 40
    .set PercentLo, 0
    .set PercentHi, 40
    .set ThrowTimerLo, 30
    .set ThrowTimerHi, 60
    .set ReactFrame, 12
    .set JabFrameLo, 15
    .set JabFrameHi, 20
    .set Jab2FrameLo, 6
    .set Jab2FrameHi, 18

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
    bl EscapeSheikThink_Constants
    mflr REG_EventConstants

    bl StoreCPUTypeAndZeroInputs

    # ON FIRST FRAME
    bl CheckIfFirstFrame
    cmpwi r3, 0x0
    beq EscapeSheikThink_Start
    # Init Positions
    mr r3, REG_P1GObj
    mr r4, REG_P2GObj
    mr r5, REG_EventData
    bl EscapeSheik_InitializePositions
    # Clear Inputs
    bl RemoveFirstFrameInputs
    # Save State
    addi r3, REG_EventData, EventData_SaveStateStruct
    li r4, 1                                            # Override failsafe code
    bl SaveState_Save

EscapeSheikThink_Start:
    # Reset if anyone died
    bl IsAnyoneDead
    cmpwi r3, 0
    bne EscapeSheikThink_Restore

EscapeSheikThink_CheckIfFailed:
    # Check if failed the Escape Sheik (grabbed))
    # EventState > EventState_Hitstun
    lbz r3, EventState(REG_EventData)
    cmpwi r3, EventState_Chase
    blt EscapeSheikThink_CheckIfFailed_End
    # Check if grabbed
    lwz r3, 0x10(P1Data)
    cmpwi r3, ASID_CapturePulledHi
    blt EscapeSheikThink_CheckIfFailed_End
    cmpwi r3, ASID_CaptureFoot
    bgt EscapeSheikThink_CheckIfFailed_End
    # Check if timer has started
    lbz r3, Timer(REG_EventData)
    cmpwi r3, 0
    bgt EscapeSheikThink_CheckIfFailed_End
    # Start Timer
    li r3, ResetTimer
    stb r3, Timer(REG_EventData)

EscapeSheikThink_CheckIfFailed_End:
EscapeSheikThink_CheckIfCPUDamaged:
    lwz r3, 0x10(REG_P2Data)
    cmpwi r3, ASID_DamageHi1
    blt EscapeSheikThink_CheckIfCPUDamaged_End
    cmpwi r3, ASID_DamageFlyRoll
    bgt EscapeSheikThink_CheckIfCPUDamaged_End
    # Check if timer has started
    lbz r3, Timer(REG_EventData)
    cmpwi r3, 0
    bgt EscapeSheikThink_CheckIfCPUDamaged_End
    # Start Timer
    li r3, ResetTimer
    stb r3, Timer(REG_EventData)

# Play Success Sound?
# Maybe increment a high score or something idk
EscapeSheikThink_CheckIfCPUDamaged_End:
EscapeSheikThink_CheckForMistimedShine:
    # Check if event state is in chase
    lbz r3, EventState(REG_EventData)
    cmpwi r3, EventState_Chase
    blt EscapeSheikThink_CheckForMistimedShine_End
    # Check if displayed already
    lbz r3, isDisplayedTiming(REG_EventData)
    cmpwi r3, 0
    bne EscapeSheikThink_CheckForMistimedShine_End
    # Get this frames inputs
    lbz r4, 0x0618(REG_P1Data)
    bl GetInputStruct
    mr r5, r3
    # Check B Button
    lwz r3, InputStruct_InstantButtons(r5)
    rlwinm. r0, r3, 0, 22, 22
    beq EscapeSheikThink_CheckForMistimedShine_End
    # Check if pushing down
    lbz r3, InputStruct_LeftAnalogY(r5)
    extsb r3, r3
    cmpwi r3, -44
    bgt EscapeSheikThink_CheckForMistimedShine_End
    # Check if in any missed tech state
    lwz r3, 0x10(REG_P1Data)
    cmpwi r3, ASID_Passive
    beq EscapeSheikThink_CheckForMistimedShine_Early
    cmpwi r3, ASID_PassiveStandB
    beq EscapeSheikThink_CheckForMistimedShine_Early
    cmpwi r3, ASID_PassiveStandF
    beq EscapeSheikThink_CheckForMistimedShine_Early
    # Check if being grabbed
    cmpwi r3, ASID_CapturePulledLw
    beq EscapeSheikThink_CheckForMistimedShine_Late
    cmpwi r3, ASID_CapturePulledHi
    beq EscapeSheikThink_CheckForMistimedShine_Late
    cmpwi r3, ASID_CaptureWaitLw
    beq EscapeSheikThink_CheckForMistimedShine_Late
    cmpwi r3, ASID_CaptureWaitHi
    beq EscapeSheikThink_CheckForMistimedShine_Late
    b EscapeSheikThink_CheckForMistimedShine_End
    .set REG_String, 20
    .set REG_Frames, 21

EscapeSheikThink_CheckForMistimedShine_Early:
    # Get early string
    bl EscapeSheikThink_EarlyText
    mflr REG_String
    # Get frames early
    mr r3, REG_P1Data
    lwz r4, 0x14(REG_P1Data)
    branchl r12, 0x80085e50
    lfs f1, 0x8(r3)
    fctiwz f1, f1
    stfd f1, 0x80(sp)
    lwz r3, 0x84(sp)
    lhz r4, TM_FramesinCurrentAS(REG_P1Data)
    sub REG_Frames, r3, r4
    b EscapeSheikThink_CheckForMistimedShine_Display

EscapeSheikThink_CheckForMistimedShine_Late:
    # Get late string
    bl EscapeSheikThink_LateText
    mflr REG_String

# Get frames late
EscapeSheikThink_CheckForMistimedShine_LateSearchInitLoop:
    .set REG_Count, 22
    li REG_Count, 0
    lhz REG_Frames, TM_FramesinCurrentAS(REG_P1Data)

EscapeSheikThink_CheckForMistimedShine_LateSearchLoop:
    # Get previous action state
    addi r3, REG_P1Data, TM_PrevASStart
    mulli r4, REG_Count, 0x2
    add r5, r3, r4
    # Check if wait
    lhz r3, 0x0(r5)
    cmpwi r3, ASID_Wait
    beq EscapeSheikThink_CheckForMistimedShine_LateSearchFoundWait
    # Add frames spent in this state
    lhz r3, 0xC(r5)
    add REG_Frames, REG_Frames, r3

EscapeSheikThink_CheckForMistimedShine_LateSearchIncLoop:
    addi REG_Count, REG_Count, 1
    cmpwi REG_Count, 6
    blt EscapeSheikThink_CheckForMistimedShine_LateSearchLoop
    b EscapeSheikThink_CheckForMistimedShine_End

EscapeSheikThink_CheckForMistimedShine_LateSearchFoundWait:
EscapeSheikThink_CheckForMistimedShine_Display:
    # Output reaction time
    mr r3, REG_P1Data                                   # p1(no offsetting window)
    li r4, 120                                          # text timeout
    li r5, 0                                            # Area to Display (0-2)
    li r6, OSD.Miscellaneous                            # Window ID(Unique to This Display)
    branchl r12, TextCreateFunction                     # create text custom function
    mr r22, r3                                          # backup text pointer

    # Create Text 1
    mr r3, r22                                          # text pointer
    bl EscapeSheikThink_TopText
    mflr r4
    lfs f1, -0x37B4(rtoc)                               # default text X/Y
    lfs f2, -0x37B4(rtoc)                               # default text X/Y
    branchl r12, Text_InitializeSubtext
    # Create Text 2
    mr r3, r22                                          # text pointer
    bl EscapeSheikThink_BottomText
    mflr r4
    mr r5, REG_Frames
    mr r6, REG_String
    lfs f1, -0x37B4(rtoc)                               # default text X/Y
    lfs f2, -0x37B0(rtoc)                               # default text X/Y
    branchl r12, Text_InitializeSubtext
    # Set as displayed
    li r3, 1
    stb r3, isDisplayedTiming(REG_EventData)

EscapeSheikThink_CheckForMistimedShine_End:
EscapeSheikThink_SwitchCase:
    # Switch Case
    lbz r3, EventState(REG_EventData)
    cmpwi r3, EventState_ThrowDelay
    beq EscapeSheikThink_ThrowDelay
    cmpwi r3, EventState_ThrowEndlag
    beq EscapeSheikThink_ThrowEndlag
    cmpwi r3, EventState_Chase
    beq EscapeSheikThink_Chase
    cmpwi r3, EventState_Reset
    beq EscapeSheikThink_Reset
    cmpwi r3, EventState_Jab2
    beq EscapeSheikThink_Jab2
    b EscapeSheikThink_CheckTimer

EscapeSheikThink_ThrowDelay:
    # Check to throw
    lhz r3, ThrowTimer(REG_EventData)
    subi r3, r3, 1
    sth r3, ThrowTimer(REG_EventData)
    cmpwi r3, 0
    bgt EscapeSheikThink_CheckTimer
    # Input DThrow
    li r3, -127
    stb r3, CPU_AnalogY(REG_P2Data)
    # Change state to attack
    li r3, EventState_ThrowEndlag
    stb r3, EventState(EventData)
    b EscapeSheikThink_CheckTimer

EscapeSheikThink_ThrowEndlag:
    # Wait for Sheik to be out of ThrowLw
    lwz r3, 0x10(REG_P2Data)
    cmpwi r3, ASID_Wait
    bne EscapeSheikThink_CheckTimer
    # Wait for P1 to be in their tech option
    lwz r3, 0x10(REG_P1Data)
    cmpwi r3, ASID_Passive
    blt EscapeSheikThink_ThrowEndlag_CheckMissTech
    cmpwi r3, ASID_PassiveStandB
    ble EscapeSheikThink_ThrowEndlag_End

EscapeSheikThink_ThrowEndlag_CheckMissTech:
    cmpwi r3, ASID_DownBoundD
    beq EscapeSheikThink_ThrowEndlag_End
    cmpwi r3, ASID_DownBoundU
    beq EscapeSheikThink_ThrowEndlag_End
    b EscapeSheikThink_CheckTimer

EscapeSheikThink_ThrowEndlag_End:
    # Advance State
    li r3, EventState_Chase
    stb r3, EventState(REG_EventData)
    b EscapeSheikThink_Chase

EscapeSheikThink_Chase:
    .set Distance, 0xB0
    .set REG_Direction, 20
    # Get Distance
    lfs f1, 0xB0(REG_P2Data)
    lfs f2, 0xB0(REG_P1Data)
    fsubs f1, f2, f1
    lfs f2, 0x2C(REG_P2Data)
    fmuls f1, f1, f2
    stfs f1, Distance(sp)
    # Get Direction
    li r3, 0
    bl IntToFloat
    lfs f2, Distance(sp)
    fcmpo cr0, f2, f1
    blt 0xC
    li REG_Direction, 1
    b 0x8
    li REG_Direction, -1

    # Determine Tech Option
    lwz r3, 0x10(REG_P1Data)
    cmpwi r3, ASID_DownBoundD
    beq EscapeSheikThink_Chase_DownBoundThink
    cmpwi r3, ASID_DownBoundU
    beq EscapeSheikThink_Chase_DownBoundThink
    # Now only run these when over frame 12
    lhz r4, TM_FramesinCurrentAS(REG_P1Data)
    cmpwi r4, ReactFrame
    blt EscapeSheikThink_CheckTimer
    cmpwi r3, ASID_Passive
    beq EscapeSheikThink_Chase_PassiveThink
    cmpwi r3, ASID_PassiveStandB
    beq EscapeSheikThink_Chase_PassiveStandThink
    cmpwi r3, ASID_PassiveStandF
    beq EscapeSheikThink_Chase_PassiveStandThink
    b EscapeSheikThink_CheckTimer

EscapeSheikThink_Chase_PassiveThink:
    # Check if facing P1
    cmpwi REG_Direction, 0
    bgt EscapeSheikThink_Chase_PassiveThink_FacingSkip
    # Input slightly towards
    lfs f1, 0x2C(REG_P2Data)
    fctiwz f1, f1
    stfd f1, 0x80(sp)
    lwz r3, 0x84(sp)
    mullw r3, r3, REG_Direction
    mulli r3, r3, 100
    stb r3, CPU_AnalogX(REG_P2Data)

EscapeSheikThink_Chase_PassiveThink_FacingSkip:
    # Check distance (if over 16 units, walk towards)
    lfs f1, GrabDistance(REG_EventConstants)
    lfs f2, Distance(sp)
    fabs f2, f2
    fcmpo cr0, f2, f1
    ble EscapeSheikThink_Chase_PassiveThink_RunTowardsSkip
    # If over 24 units, run towards
    lfs f1, RunDistance(REG_EventConstants)
    fcmpo cr0, f2, f1
    bgt EscapeSheikThink_Chase_PassiveThink_RunTowards

EscapeSheikThink_Chase_PassiveThink_WalkTowards:
    # Walk Towards
    lfs f1, 0x2C(REG_P2Data)
    fctiwz f1, f1
    stfd f1, 0x80(sp)
    lwz r3, 0x84(sp)
    mullw r3, r3, REG_Direction
    mulli r3, r3, 100
    stb r3, CPU_AnalogX(REG_P2Data)
    b EscapeSheikThink_Chase_PassiveThink_RunTowardsSkip

EscapeSheikThink_Chase_PassiveThink_RunTowards:
    # Run Towards
    lfs f1, 0x2C(REG_P2Data)
    fctiwz f1, f1
    stfd f1, 0x80(sp)
    lwz r3, 0x84(sp)
    mullw r3, r3, REG_Direction
    mulli r3, r3, 127
    stb r3, CPU_AnalogX(REG_P2Data)

EscapeSheikThink_Chase_PassiveThink_RunTowardsSkip:
    # Check distance
    lfs f1, GrabDistance(REG_EventConstants)
    lfs f2, Distance(sp)
    fabs f2, f2
    fcmpo cr0, f2, f1
    bgt EscapeSheikThink_Chase_PassiveThink_HoldShieldSkip
    # Check State
    lwz r3, 0x10(REG_P2Data)
    cmpwi r3, ASID_Dash
    beq EscapeSheikThink_Chase_PassiveThink_HoldShield
    cmpwi r3, ASID_Run
    beq EscapeSheikThink_Chase_PassiveThink_HoldShield
    b EscapeSheikThink_Chase_PassiveThink_HoldShieldSkip

EscapeSheikThink_Chase_PassiveThink_HoldShield:
    # Enter shield
    mr r3, REG_P2GObj
    branchl r12, AS_Guard
    # And hold
    li r3, PAD_TRIGGER_R
    stw r3, CPU_HeldButtons(REG_P2Data)
    b EscapeSheikThink_Chase_PassiveThink_HoldShieldSkip

EscapeSheikThink_Chase_PassiveThink_HoldShieldSkip:
    # Now grab when P1 is on frame 20
    lhz r3, TM_FramesinCurrentAS(REG_P1Data)
    cmpwi r3, 20
    blt EscapeSheikThink_CheckTimer
    # Enter grab
    mr r3, REG_P2GObj
    li r4, 0xD4
    branchl r12, AS_Catch
    # Advance state
    li r3, EventState_Reset
    stb r3, EventState(REG_EventData)
    # Start timer
    li r3, ResetTimer
    stb r3, Timer(REG_EventData)
    b EscapeSheikThink_CheckTimer

EscapeSheikThink_Chase_PassiveStandThink:
    # Check if facing P1
    cmpwi REG_Direction, 0
    bgt EscapeSheikThink_Chase_PassiveStandThink_FacingSkip
    # BUT is he coming to me?
    lfs f2, 0xC8(REG_P1Data)
    li r3, 0
    bl IntToFloat
    li r3, 1                                            # Moving Right
    fcmpo cr0, f2, f1
    bgt 0x8
    li r3, -1                                           # Moving Left
    lfs f1, 0x2C(REG_P2Data)
    fctiwz f1, f1
    stfd f1, 0x80(sp)
    lwz r4, 0x84(sp)
    mullw r4, r4, REG_Direction
    cmpw r3, r4
    bne EscapeSheikThink_Chase_PassiveStandThink_FacingSkip
    # If under frame 20, run instead
    li r5, 127
    lhz r3, TM_FramesinCurrentAS(REG_P1Data)
    cmpwi r3, 20
    blt 0x8
    li r5, 100
    # Input slightly towards
    lfs f1, 0x2C(REG_P2Data)
    fctiwz f1, f1
    stfd f1, 0x80(sp)
    lwz r3, 0x84(sp)
    mullw r3, r3, REG_Direction
    mullw r3, r3, r5
    stb r3, CPU_AnalogX(REG_P2Data)

EscapeSheikThink_Chase_PassiveStandThink_FacingSkip:
    # Check distance (if over 16 units, run towards)
    lfs f1, GrabDistance(REG_EventConstants)
    lfs f2, Distance(sp)
    fabs f2, f2
    fcmpo cr0, f2, f1
    ble EscapeSheikThink_Chase_PassiveStandThink_RunTowardsSkip
    # Wait until no longer turning
    lwz r3, 0x10(REG_P2Data)
    cmpwi r3, ASID_Turn
    bne EscapeSheikThink_Chase_PassiveStandThink_RunTowardCheckMovementDirection
    # If turning, wait til frame 2 to make a decision
    lhz r3, TM_FramesinCurrentAS(REG_P2Data)
    cmpwi r3, 2
    bge EscapeSheikThink_Chase_PassiveStandThink_RunTowardsSkip

EscapeSheikThink_Chase_PassiveStandThink_RunTowardCheckMovementDirection:
    # BUT is he coming to me?
    lfs f2, 0xC8(REG_P1Data)
    li r3, 0
    bl IntToFloat
    li r3, 1                                            # Moving Right
    fcmpo cr0, f2, f1
    bgt 0x8
    li r3, -1                                           # Moving Left
    lfs f1, 0x2C(REG_P2Data)
    fctiwz f1, f1
    stfd f1, 0x80(sp)
    lwz r4, 0x84(sp)
    mullw r4, r4, REG_Direction
    cmpw r3, r4
    bne EscapeSheikThink_Chase_PassiveStandThink_RunTowardsSkip

EscapeSheikThink_Chase_PassiveStandThink_RunTowards:
    # Run Towards
    lfs f1, 0x2C(REG_P2Data)
    fctiwz f1, f1
    stfd f1, 0x80(sp)
    lwz r3, 0x84(sp)
    mullw r3, r3, REG_Direction
    mulli r3, r3, 127
    stb r3, CPU_AnalogX(REG_P2Data)

EscapeSheikThink_Chase_PassiveStandThink_RunTowardsSkip:
    # If and within range and running, hold shield
    # Check distance
    lfs f1, GrabDistance(REG_EventConstants)
    lfs f2, Distance(sp)
    fabs f2, f2
    fcmpo cr0, f2, f1
    bgt EscapeSheikThink_Chase_PassiveStandThink_HoldShieldSkip
    lwz r3, 0x10(REG_P2Data)
    cmpwi r3, ASID_Dash
    beq EscapeSheikThink_Chase_PassiveStandThink_HoldShieldCheckFrame
    cmpwi r3, ASID_Run
    beq EscapeSheikThink_Chase_PassiveStandThink_HoldShieldCheckFrame
    b EscapeSheikThink_Chase_PassiveStandThink_HoldShieldSkip

EscapeSheikThink_Chase_PassiveStandThink_HoldShieldCheckFrame:
    lhz r3, TM_FramesinCurrentAS(REG_P1Data)
    cmpwi r3, 28
    bge EscapeSheikThink_Chase_PassiveStandThink_HoldShield

EscapeSheikThink_Chase_PassiveStandThink_HoldShieldCheckVelocity:
    # Allow to hold shield earlier than usual if the character isnt moving very far
    lfs f1, 0xC8(REG_P1Data)
    fabs f1, f1,
    lfs f2, HoldShieldVelocity(REG_EventConstants)
    fcmpo cr0, f1, f2
    bgt EscapeSheikThink_Chase_PassiveStandThink_HoldShieldRunInstead

EscapeSheikThink_Chase_PassiveStandThink_HoldShield:
    # Enter shield
    mr r3, REG_P2GObj
    branchl r12, AS_Guard
    # And hold
    li r3, PAD_TRIGGER_R
    stw r3, CPU_HeldButtons(REG_P2Data)
    b EscapeSheikThink_Chase_PassiveStandThink_HoldShieldSkip

EscapeSheikThink_Chase_PassiveStandThink_HoldShieldRunInstead:
    # Run Towards
    lfs f1, 0x2C(REG_P2Data)
    fctiwz f1, f1
    stfd f1, 0x80(sp)
    lwz r3, 0x84(sp)
    mullw r3, r3, REG_Direction
    mulli r3, r3, 127
    stb r3, CPU_AnalogX(REG_P2Data)

EscapeSheikThink_Chase_PassiveStandThink_HoldShieldSkip:
    # Now grab when P1 is on frame 34
    lhz r3, TM_FramesinCurrentAS(REG_P1Data)
    cmpwi r3, 34
    blt EscapeSheikThink_CheckTimer
    # Enter grab
    mr r3, REG_P2GObj
    li r4, 0xD4
    branchl r12, AS_Catch
    # Advance state
    li r3, EventState_Reset
    stb r3, EventState(REG_EventData)
    # Start timer
    li r3, ResetTimer
    stb r3, Timer(REG_EventData)
    b EscapeSheikThink_CheckTimer

EscapeSheikThink_Chase_DownBoundThink:
    # Determine jab frame
    lbz r3, JabFrame(REG_EventData)
    cmpwi r3, 0
    bne EscapeSheikThink_Chase_DownBoundThink_JabFrameInitSkip
    # Init Jab Frame
    li r3, JabFrameHi-JabFrameLo
    branchl r12, HSD_Randi
    addi r3, r3, JabFrameLo
    stb r3, JabFrame(REG_EventData)
    # Get chance to jab again
    li r3, 2
    branchl r12, HSD_Randi
    stb r3, isJabTwice(REG_EventData)
    # Get frame to jab again
    li r3, Jab2FrameHi-Jab2FrameLo
    branchl r12, HSD_Randi
    addi r3, r3, Jab2FrameLo
    stb r3, Jab2Frame(REG_EventData)
    # Init Jab 2 Timer
    li r3, 0
    stb r3, Jab2Timer(REG_EventData)

EscapeSheikThink_Chase_DownBoundThink_JabFrameInitSkip:
    # Check if facing P1
    cmpwi REG_Direction, 0
    bgt EscapeSheikThink_Chase_DownBoundThink_FacingSkip
    # Input slightly towards
    lfs f1, 0x2C(REG_P2Data)
    fctiwz f1, f1
    stfd f1, 0x80(sp)
    lwz r3, 0x84(sp)
    mullw r3, r3, REG_Direction
    mulli r3, r3, 100
    stb r3, CPU_AnalogX(REG_P2Data)

EscapeSheikThink_Chase_DownBoundThink_FacingSkip:
    # Check distance (if over 16 units, walk towards)
    lfs f1, GrabDistance(REG_EventConstants)
    lfs f2, Distance(sp)
    fabs f2, f2
    fcmpo cr0, f2, f1
    ble EscapeSheikThink_Chase_DownBoundThink_RunTowardsSkip

EscapeSheikThink_Chase_DownBoundThink_WalkTowards:
    # Walk Towards
    lfs f1, 0x2C(REG_P2Data)
    fctiwz f1, f1
    stfd f1, 0x80(sp)
    lwz r3, 0x84(sp)
    mullw r3, r3, REG_Direction
    mulli r3, r3, 100
    stb r3, CPU_AnalogX(REG_P2Data)

EscapeSheikThink_Chase_DownBoundThink_RunTowardsSkip:
    # Check distance
    lfs f1, GrabDistance(REG_EventConstants)
    lfs f2, Distance(sp)
    fabs f2, f2
    fcmpo cr0, f2, f1
    bgt EscapeSheikThink_Chase_DownBoundThink_HaltSkip
    # Ensure Facing
    cmpwi REG_Direction, 1
    bne EscapeSheikThink_Chase_DownBoundThink_HaltSkip

EscapeSheikThink_Chase_DownBoundThink_Halt:
    # Stop Moving
    li r3, 0
    stw r3, CPU_HeldButtons(REG_P2Data)
    stb r3, CPU_AnalogX(REG_P2Data)

EscapeSheikThink_Chase_DownBoundThink_HaltSkip:
    # Now jab when P1 is on the jab frame
    lhz r3, TM_FramesinCurrentAS(REG_P1Data)
    lbz r4, JabFrame(REG_EventData)
    cmpw r3, r4
    blt EscapeSheikThink_CheckTimer
    # Enter jab
    li r3, PAD_BUTTON_A
    stw r3, CPU_HeldButtons(REG_P2Data)
    li r3, 0
    stb r3, CPU_AnalogX(REG_P2Data)
    # Check if sheik will double jab
    lbz r3, isJabTwice(REG_EventData)
    cmpwi r3, 0
    beq EscapeSheikThink_Chase_DownBoundThink_SingleJab
    # Start Double Jab timer
    lbz r3, Jab2Frame(REG_EventData)
    stb r3, Jab2Timer(REG_EventData)
    # Change Event State
    li r3, EventState_Jab2
    stb r3, EventState(REG_EventData)
    b EscapeSheikThink_CheckTimer

EscapeSheikThink_Chase_DownBoundThink_SingleJab:
    # Advance state
    li r3, EventState_Reset
    stb r3, EventState(REG_EventData)
    # Start timer
    li r3, ResetTimer+30
    stb r3, Timer(REG_EventData)
    b EscapeSheikThink_CheckTimer

EscapeSheikThink_Jab2:
    # Check if waiting on jab 2
    lbz r3, Jab2Timer(REG_EventData)
    cmpwi r3, 0
    beq EscapeSheikThink_Chase_DownBoundThink_Jab2Skip
    # But not during hitlag
    lbz r3, 0x221A(REG_P2Data)
    rlwinm. r3, r3, 0, 26, 26
    bne EscapeSheikThink_Chase_DownBoundThink_Jab2Skip
    # Decrement timer
    lbz r3, Jab2Timer(REG_EventData)
    subi r3, r3, 1
    stb r3, Jab2Timer(REG_EventData)
    # Check if up
    cmpwi r3, 0
    bgt EscapeSheikThink_CheckTimer
    # Enter jab
    li r3, PAD_BUTTON_A
    stw r3, CPU_HeldButtons(REG_P2Data)
    li r3, 0
    stb r3, CPU_AnalogX(REG_P2Data)
    # Advance state
    li r3, EventState_Reset
    stb r3, EventState(REG_EventData)
    # Start timer
    li r3, ResetTimer+30
    stb r3, Timer(REG_EventData)
    b EscapeSheikThink_CheckTimer

EscapeSheikThink_Chase_DownBoundThink_Jab2Skip:
    b EscapeSheikThink_CheckTimer

EscapeSheikThink_Reset:
    # Hold Shield
    li r3, PAD_TRIGGER_R
    stw r3, CPU_HeldButtons(REG_P2Data)
    b EscapeSheikThink_CheckTimer

EscapeSheikThink_CheckTimer:
    # Check if timer exists
    lbz r3, Timer(REG_EventData)
    cmpwi r3, 0
    ble EscapeSheikThink_Exit
    # Decrement timer
    subi r3, r3, 1
    stb r3, Timer(REG_EventData)
    cmpwi r3, 0
    bgt EscapeSheikThink_Exit

EscapeSheikThink_Restore:
    # Restore State
    addi r3, REG_EventData, EventData_SaveStateStruct
    li r4, 1
    bl SaveState_Load
    # Init Positions Again
    mr r3, REG_P1GObj
    mr r4, REG_P2GObj
    mr r5, REG_EventData
    bl EscapeSheik_InitializePositions

EscapeSheikThink_Exit:
    restore
    blr

################################

EscapeSheikThink_Constants:
    blrl
    .set P1X, 0x0
    .set P1Y, 0x4
    .set P2X, 0x8
    .set P2Y, 0xC
    .set GrabDistance, 0x10
    .set HoldShieldVelocity, 0x14
    .set RunDistance, 0x18

    .float -8                                           # p1 x
    .float 0                                            # p1 y
    .float 8                                            # p2 x
    .float 0                                            # p2 y
    .float 14                                           # 16
    .float 1.1
    .float 23

###########################################

EscapeSheikThink_TopText:
    blrl
    .string "Down B Input"
    .align 2

EscapeSheikThink_BottomText:
    blrl
    .string "%df %s"
    .align 2

EscapeSheikThink_EarlyText:
    blrl
    .string "Early"
    .align 2

EscapeSheikThink_LateText:
    blrl
    .string "Late"
    .align 2

###########################################

EscapeSheik_InitializePositions:
    backup

    .set REG_FacingDirection, 31                        # 1 = p1 facing right, -1 = p1 facing left
    .set REG_P1GObj, 30
    .set REG_P1Data, 29
    .set REG_P2GObj, 28
    .set REG_P2Data, 27
    .set REG_EventData, 26

    # Init Registers
    mr REG_P1GObj, r3
    lwz REG_P1Data, 0x2C(REG_P1GObj)
    mr REG_P2GObj, r4
    lwz REG_P2Data, 0x2C(REG_P2GObj)
    mr REG_EventData, r5

EscapeSheik_InitializePositions_DetermineFacingDirection:
    # Determine Facing Direction
    li REG_FacingDirection, 1
    li r3, 2
    branchl r12, HSD_Randi
    cmpwi r3, 0
    beq EscapeSheik_InitializePositions_DetermineFacingDirection_End
    li REG_FacingDirection, -1

EscapeSheik_InitializePositions_DetermineFacingDirection_End:
    # Apply Facing Directions
    mr r3, REG_FacingDirection
    bl IntToFloat
    stfs f1, 0x2C(REG_P1Data)
    mulli r3, REG_FacingDirection, -1
    bl IntToFloat
    stfs f1, 0x2C(REG_P2Data)

    # Get Starting Coordinates
    lfs f1, P1X(REG_EventConstants)
    lfs f2, P1Y(REG_EventConstants)
    cmpwi REG_FacingDirection, 0
    blt EscapeSheik_InitializePositions_P1FacingLeft
    stfs f1, 0xB0(REG_P1Data)
    stfs f2, 0xB4(REG_P1Data)
    b EscapeSheik_InitializePositions_RightPosition

EscapeSheik_InitializePositions_P1FacingLeft:
    stfs f1, 0xB0(REG_P2Data)
    stfs f2, 0xB4(REG_P2Data)

EscapeSheik_InitializePositions_RightPosition:
    lfs f1, P1X(REG_EventConstants)
    lfs f2, P1Y(REG_EventConstants)
    cmpwi REG_FacingDirection, 0
    blt EscapeSheik_InitializePositions_P2FacingRight
    stfs f1, 0xB0(REG_P2Data)
    stfs f2, 0xB4(REG_P2Data)

EscapeSheik_InitializePositions_P2FacingRight:
    stfs f1, 0xB0(REG_P1Data)
    stfs f2, 0xB4(REG_P1Data)
    # Update Positions
    mr r3, REG_P1GObj
    bl PlacePlayerOnGround
    mr r3, REG_P1GObj
    bl UpdateCameraBox
    mr r3, REG_P2GObj
    bl PlacePlayerOnGround
    mr r3, REG_P2GObj
    bl UpdateCameraBox

    # Store P1 into P2 Grab Pointer
    stw REG_P1GObj, 0x1A58(REG_P2Data)
    stw REG_P1GObj, 0x1A5C(REG_P2Data)
    # Clear P1's Grabbed Player Pointer
    li r3, 0
    stw r3, 0x1A58(REG_P1Data)
    stw r3, 0x1A5C(REG_P1Data)
    # Clear P2's GFX Pointer
    stw r3, 0x60C(REG_P2Data)
    # Enter P2 Into Grab
    mr r3, REG_P2GObj                                   # P2 Enters Grab
    branchl r12, AS_GrabOpponent
    # Enter P1 Into Grabbed
    mr r3, REG_P1GObj                                   # P1 Grabbed
    mr r4, REG_P2GObj                                   # P2 = Grabber
    branchl r12, AS_Grabbed
    # Enter P2 Into GrabWait
    mr r3, REG_P2GObj                                   # P2 Enters GrabWait
    branchl r12, AS_CatchWait
    # Give a bunch of grabstun
    li r3, 999
    bl IntToFloat
    stfs f1, 0x1A4C(REG_P1Data)

    # Random percent
    li r3, PercentHi-PercentLo
    branchl r12, HSD_Randi
    addi r4, r3, PercentLo
    lbz r3, 0xC(REG_P1Data)
    branchl r12, PlayerBlock_SetDamage

    # Reset Variables
    li r3, EventState_ThrowDelay
    stb r3, EventState(REG_EventData)
    li r3, 0
    stb r3, Timer(REG_EventData)
    stb r3, JabFrame(REG_EventData)
    # Init Throw Timer
    li r3, ThrowTimerHi-ThrowTimerLo
    branchl r12, HSD_Randi
    addi r3, r3, ThrowTimerLo
    sth r3, ThrowTimer(REG_EventData)
    # Init isDisplayedTiming
    li r3, 0
    stb r3, isDisplayedTiming(REG_EventData)

EscapeSheik_InitializePositions_Exit:
    restore
    blr
