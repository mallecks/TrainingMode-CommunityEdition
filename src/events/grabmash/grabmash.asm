###########################
## Grab Mash Out HIJACK INFO ##
###########################

GrabMashOut:
    # Store Stage, CPU, and FDD Toggles
    lwz r3, 0x0(r29)                                    # Send event struct
    mr r4, r26                                          # Send match struct
    li r5, Marth.Ext
    li r6, FinalDestination                             # Use chosen Stage
    load r7, EventOSD_GrabMashOut
    li r8, 1                                            # Use Sopo bool
    bl InitializeMatch

# STORE THINK FUNCTION
GrabMashOutStoreThink:
    bl GrabMashOutLoad
    mflr r3
    stw r3, 0x44(r26)                                   # on match load

    b exit

##################################
## Grab Mash Out LOAD FUNCT ##
##################################
GrabMashOutLoad:
    blrl

    backup

    # Schedule Think
    bl GrabMashOutThink
    mflr r3
    li r4, 3                                            # Priority (After EnvCOllision)
    li r5, 0
    bl CreateEventThinkFunction
    b GrabMashOutThink_Exit

###################################
## Grab Mash Out THINK FUNCT ##
###################################

GrabMashOutThink:
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
    .set EventState_MashOutThink, 0x1
    .set EventState_Reset, 0x2
    .set Timer, 0x1
    .set ThrowTimer, 0x2
    .set GrabBreakout, 0x4

    # Constants
    .set ResetTimer, 80
    .set PercentLo, 0
    .set PercentHi, 80
    .set ThrowTimerLo, 40
    .set ThrowTimerHi, 100

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
    bl GrabMashOutThink_Constants
    mflr REG_EventConstants

    bl StoreCPUTypeAndZeroInputs

    # ON FIRST FRAME
    bl CheckIfFirstFrame
    cmpwi r3, 0x0
    beq GrabMashOutThink_Start
    # Init Positions
    mr r3, REG_P1GObj
    mr r4, REG_P2GObj
    mr r5, REG_EventData
    bl GrabMashOut_InitializePositions
    # Clear Inputs
    bl RemoveFirstFrameInputs
    # Save State
    addi r3, REG_EventData, EventData_SaveStateStruct
    li r4, 1                                            # Override failsafe code
    bl SaveState_Save

GrabMashOutThink_Start:
    # Reset if anyone died
    bl IsAnyoneDead
    cmpwi r3, 0
    bne GrabMashOutThink_Restore

GrabMashOutThink_SwitchCase:
    # Switch Case
    lbz r3, EventState(REG_EventData)
    cmpwi r3, EventState_ThrowDelay
    beq GrabMashOutThink_ThrowDelay
    cmpwi r3, EventState_MashOutThink
    beq GrabMashOutThink_MashOutThink
    cmpwi r3, EventState_Reset
    beq GrabMashOutThink_Reset
    b GrabMashOutThink_CheckTimer

GrabMashOutThink_ThrowDelay:
    # Check to grab
    lhz r3, ThrowTimer(REG_EventData)
    subi r3, r3, 1
    sth r3, ThrowTimer(REG_EventData)
    cmpwi r3, 0
    bne GrabMashOutThink_ThrowDelay_TimerSkip
    # Input grab
    li r3, PAD_BUTTON_A | PAD_TRIGGER_R
    stw r3, CPU_HeldButtons(REG_P2Data)

GrabMashOutThink_ThrowDelay_TimerSkip:
    # Check if P1 was grabbed
    lwz r3, 0x10(REG_P1Data)
    cmpwi r3, ASID_CaptureWaitLw
    beq GrabMashOutThink_ThrowDelay_Grabbed
    cmpwi r3, ASID_CaptureWaitHi
    beq GrabMashOutThink_ThrowDelay_Grabbed
    # If just grabbed, skip
    cmpwi r3, ASID_CapturePulledLw
    beq GrabMashOutThink_CheckTimer
    cmpwi r3, ASID_CapturePulledHi
    beq GrabMashOutThink_CheckTimer
    # Check if P1 acted early
    cmpwi r3, ASID_Wait
    bne GrabMashOutThink_ThrowDelay_ActedEarly
    b GrabMashOutThink_CheckTimer

GrabMashOutThink_ThrowDelay_Grabbed:
    # Get breakout timer
    lfs f1, 0x2354(REG_P1Data)
    stfs f1, GrabBreakout(REG_EventData)
    # Change state to attack
    li r3, EventState_MashOutThink
    stb r3, EventState(EventData)
    b GrabMashOutThink_CheckTimer

GrabMashOutThink_ThrowDelay_ActedEarly:
    # Play Error Noise
    li r3, 0xAF
    bl PlaySFX
    # Set Timer
    li r3, ResetTimer-40
    stb r3, Timer(REG_EventData)
    # Change state to reset
    li r3, EventState_Reset
    stb r3, EventState(EventData)
    b GrabMashOutThink_CheckTimer

GrabMashOutThink_MashOutThink:
    # Wait for P1 to be in CaptureCut
    lwz r3, 0x10(REG_P1Data)
    cmpwi r3, ASID_CaptureJump
    beq GrabMashOutThink_BrokeOut
    cmpwi r3, ASID_CaptureCut
    beq GrabMashOutThink_BrokeOut
    b GrabMashOutThink_CheckTimer

GrabMashOutThink_BrokeOut:
    # Set reset timer
    li r3, ResetTimer
    stb r3, Timer(REG_EventData)
    # Advance State
    li r3, EventState_Reset
    stb r3, EventState(REG_EventData)
    b GrabMashOutThink_CheckTimer

GrabMashOutThink_Reset:
    b GrabMashOutThink_CheckTimer

GrabMashOutThink_CheckTimer:
    # Check if timer exists
    lbz r3, Timer(REG_EventData)
    cmpwi r3, 0
    ble GrabMashOutThink_Exit
    # Decrement timer
    subi r3, r3, 1
    stb r3, Timer(REG_EventData)
    cmpwi r3, 0
    bgt GrabMashOutThink_Exit

GrabMashOutThink_Restore:
    # Restore State
    addi r3, REG_EventData, EventData_SaveStateStruct
    li r4, 1
    bl SaveState_Load
    # Init Positions Again
    mr r3, REG_P1GObj
    mr r4, REG_P2GObj
    mr r5, REG_EventData
    bl GrabMashOut_InitializePositions

GrabMashOutThink_Exit:
    restore
    blr

################################

GrabMashOutThink_Constants:
    blrl
    .set P1X, 0x0
    .set P1Y, 0x4
    .set P2X, 0x8
    .set P2Y, 0xC

    .float -8                                           # p1 x
    .float 0                                            # p1 y
    .float 8                                            # p2 x
    .float 0                                            # p2 y

###########################################

GrabMashOut_TopText:
    blrl
    .string "Escaped Grab"
    .align 2

GrabMashOut_BottomText:
    blrl
    .string "Frame %d/%d"
    .align 2

###########################################

GrabMashOut_InitializePositions:
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

GrabMashOut_InitializePositions_DetermineFacingDirection:
    # Determine Facing Direction
    li REG_FacingDirection, 1
    li r3, 2
    branchl r12, HSD_Randi
    cmpwi r3, 0
    beq GrabMashOut_InitializePositions_DetermineFacingDirection_End
    li REG_FacingDirection, -1

GrabMashOut_InitializePositions_DetermineFacingDirection_End:
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
    blt GrabMashOut_InitializePositions_P1FacingLeft
    stfs f1, 0xB0(REG_P1Data)
    stfs f2, 0xB4(REG_P1Data)
    b GrabMashOut_InitializePositions_RightPosition

GrabMashOut_InitializePositions_P1FacingLeft:
    stfs f1, 0xB0(REG_P2Data)
    stfs f2, 0xB4(REG_P2Data)

GrabMashOut_InitializePositions_RightPosition:
    lfs f1, P2X(REG_EventConstants)
    lfs f2, P2Y(REG_EventConstants)
    cmpwi REG_FacingDirection, 0
    blt GrabMashOut_InitializePositions_P2FacingRight
    stfs f1, 0xB0(REG_P2Data)
    stfs f2, 0xB4(REG_P2Data)
    b GrabMashOut_InitializePositions_FacingEnd

GrabMashOut_InitializePositions_P2FacingRight:
    stfs f1, 0xB0(REG_P1Data)
    stfs f2, 0xB4(REG_P1Data)

GrabMashOut_InitializePositions_FacingEnd:
    # Update Positions
    mr r3, REG_P1GObj
    bl PlacePlayerOnGround
    mr r3, REG_P1GObj
    bl UpdateCameraBox
    mr r3, REG_P2GObj
    bl PlacePlayerOnGround
    mr r3, REG_P2GObj
    bl UpdateCameraBox

    # Enter P1 Into Wait
    mr r3, REG_P1GObj
    branchl r12, AS_Wait
    # Enter P2 Into Wait
    mr r3, REG_P2GObj
    branchl r12, AS_Wait

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
    # Init Throw Timer
    li r3, ThrowTimerHi-ThrowTimerLo
    branchl r12, HSD_Randi
    addi r3, r3, ThrowTimerLo
    sth r3, ThrowTimer(REG_EventData)

GrabMashOut_InitializePositions_Exit:
    restore
    blr
