###########################
## SideB Sweetspot HIJACK INFO ##
###########################

SideBSweetspot:
    # Store Stage, CPU, and FDD Toggles
    lwz r3, 0x0(r29)                                    # Send event struct
    mr r4, r26                                          # Send match struct
    li r5, Marth.Ext
    li r6, -1                                           # Use chosen Stage
    load r7, EventOSD_SideBSweetspot
    li r8, 0                                            # Use Sopo bool
    bl InitializeMatch

# STORE THINK FUNCTION
SideBSweetspotStoreThink:
    bl SideBSweetspotLoad
    mflr r3
    stw r3, 0x44(r26)                                   # on match load

    b exit

##################################
## SideB Sweetspot LOAD FUNCT ##
##################################
SideBSweetspotLoad:
    blrl

    backup

    # Schedule Think
    bl SideBSweetspotThink
    mflr r3
    li r4, 3                                            # Priority (After EnvCOllision)
    li r5, 0
    bl CreateEventThinkFunction
    b SideBSweetspotThink_Exit

###################################
## SideB Sweetspot THINK FUNCT ##
###################################

SideBSweetspotThink:
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
    .set EventState_Endlag, 0x0
    .set EventState_WaitToAttack, 0x1
    .set EventState_AttackThink, 0x2
    .set EventState_Reset, 0x3
    .set Timer, 0x1
    .set ThrowTimer, 0x2
    .set JabFrame, 0x4

    # Constants
    .set ResetTimer, 30
    .set AngleLo, 45
    .set AngleHi, 60
    .set MagLo, 106                                     # 106
    .set MagHi, 135                                     # 120
    .set PercentHi, 100
    .set PercentLo, 50

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
    bl SideBSweetspotThink_Constants
    mflr REG_EventConstants

    bl StoreCPUTypeAndZeroInputs

    # ON FIRST FRAME
    bl CheckIfFirstFrame
    cmpwi r3, 0x0
    beq SideBSweetspotThink_Start
    # Init Positions
    mr r3, REG_P1GObj
    mr r4, REG_P2GObj
    mr r5, REG_EventData
    bl SideBSweetspot_InitializePositions
    # Clear Inputs
    bl RemoveFirstFrameInputs
    # Save State
    addi r3, REG_EventData, EventData_SaveStateStruct
    li r4, 1                                            # Override failsafe code
    bl SaveState_Save

SideBSweetspotThink_Start:
    # P2 intangible
    mr r3, P2GObj
    li r4, 1
    branchl r12, ApplyIntangibility

    # Reset if anyone died
    bl IsAnyoneDead
    cmpwi r3, 0
    bne SideBSweetspotThink_Restore

SideBSweetspotThink_Crouch:
    # Always hold crouch when state is higher than EventState_Endlag
    lbz r3, EventState(REG_EventData)
    cmpwi r3, EventState_Endlag
    ble SideBSweetspotThink_CrouchSkip
    # Input crouch
    li r3, -127
    stb r3, CPU_AnalogY(REG_P2Data)

SideBSweetspotThink_CrouchSkip:
SideBSweetspotThink_SwitchCase:
    # Switch Case
    lbz r3, EventState(REG_EventData)
    cmpwi r3, EventState_Endlag
    beq SideBSweetspotThink_Endlag
    cmpwi r3, EventState_WaitToAttack
    beq SideBSweetspotThink_WaitToAttack
    cmpwi r3, EventState_AttackThink
    beq SideBSweetspotThink_AttackThink
    cmpwi r3, EventState_Reset
    beq SideBSweetspotThink_Reset
    b SideBSweetspotThink_CheckTimer

SideBSweetspotThink_Endlag:
    # Check if in Wait
    lwz r3, 0x10(P2Data)
    cmpwi r3, ASID_Wait
    bne SideBSweetspotThink_CheckTimer
    # Input Crouch
    li r3, -127
    stb r3, CPU_AnalogY(REG_P2Data)
    # Change state to attack
    li r3, EventState_WaitToAttack
    stb r3, EventState(EventData)
    b SideBSweetspotThink_CheckTimer

SideBSweetspotThink_WaitToAttack:
    # Wait for Fox to be in SpecialAirS
    lwz r3, 0x10(REG_P1Data)
    cmpwi r3, 0x15F
    bne SideBSweetspotThink_WaitToAttackSkip
    # Input Dtilt
    li r3, PAD_BUTTON_A
    stw r3, CPU_HeldButtons(REG_P2Data)
    li r3, -38
    stb r3, CPU_AnalogY(REG_P2Data)
    # Advance State
    li r3, EventState_AttackThink
    stb r3, EventState(REG_EventData)
    b SideBSweetspotThink_CheckTimer

SideBSweetspotThink_WaitToAttackSkip:
    # Check if fox up-b'd
    cmpwi r3, 0x162
    beq SideBSweetspotThink_WaitToAttack_BlacklistMove
    cmpwi r3, ASID_EscapeAir
    beq SideBSweetspotThink_WaitToAttack_BlacklistMove
    b SideBSweetspotThink_WaitToAttack_CheckForBlacklistMovesSkip

SideBSweetspotThink_WaitToAttack_BlacklistMove:
    # PLay Error SFX
    li r3, 0xAF
    bl PlaySFX
    # Start Timer
    li r3, ResetTimer
    stb r3, Timer(REG_EventData)
    # Advance State
    li r3, EventState_Reset
    stb r3, EventState(REG_EventData)
    b SideBSweetspotThink_CheckTimer

SideBSweetspotThink_WaitToAttack_CheckForBlacklistMovesSkip:
SideBSweetspotThink_AttackThink:
    # Check if d-tilting
    lwz r3, 0x10(REG_P2Data)
    cmpwi r3, ASID_AttackLw3
    bne SideBSweetspotThink_CheckTimer
    # Check if frame 7
    li r3, 7
    bl IntToFloat
    lfs f2, 0x894(REG_P2Data)
    fcmpo cr0, f1, f2
    bne SideBSweetspotThink_AttackThink_FreezeSkip
    # Check if already frozen
    li r3, 0
    bl IntToFloat
    lfs f2, 0x89C(REG_P2Data)
    fcmpo cr0, f1, f2
    beq SideBSweetspotThink_AttackThink_FreezeCheckToUnfreeze
    # Freeze
    mr r3, REG_P2GObj
    branchl r12, FrameSpeedChange
    b SideBSweetspotThink_AttackThink_FreezeSkip

SideBSweetspotThink_AttackThink_FreezeCheckToUnfreeze:
    # Check if player was hit
    lwz r3, 0x2094(REG_P2Data)
    cmpwi r3, 0
    beq SideBSweetspotThink_AttackThink_FreezeSkip
    # Unfreeze
    li r3, 1
    bl IntToFloat
    mr r3, REG_P2GObj
    branchl r12, FrameSpeedChange
    # Start Timer
    li r3, ResetTimer
    stb r3, Timer(REG_EventData)
    # Advance State
    li r3, EventState_Reset
    stb r3, EventState(REG_EventData)
    b SideBSweetspotThink_CheckTimer

SideBSweetspotThink_AttackThink_FreezeSkip:
    # Check if P1 grabbed ledge successfully
    lwz r3, 0x10(REG_P1Data)
    cmpwi r3, ASID_CliffCatch
    bne SideBSweetspotThink_AttackThink_CliffCatchSkip
    # Play Success SFX
    li r3, 0xAD
    bl PlaySFX
    # Unfreeze P2
    li r3, 1
    bl IntToFloat
    mr r3, REG_P2GObj
    branchl r12, FrameSpeedChange
    # Start Timer
    li r3, ResetTimer+30
    stb r3, Timer(REG_EventData)
    # Advance State
    li r3, EventState_Reset
    stb r3, EventState(REG_EventData)
    b SideBSweetspotThink_CheckTimer

SideBSweetspotThink_AttackThink_CliffCatchSkip:
SideBSweetspotThink_Reset:
    b SideBSweetspotThink_CheckTimer

SideBSweetspotThink_CheckTimer:
    # Check if timer exists
    lbz r3, Timer(REG_EventData)
    cmpwi r3, 0
    ble SideBSweetspotThink_Exit
    # Decrement timer
    subi r3, r3, 1
    stb r3, Timer(REG_EventData)
    cmpwi r3, 0
    bgt SideBSweetspotThink_Exit

SideBSweetspotThink_Restore:
    # Restore State
    addi r3, REG_EventData, EventData_SaveStateStruct
    li r4, 1
    bl SaveState_Load
    # Init Positions Again
    mr r3, REG_P1GObj
    mr r4, REG_P2GObj
    mr r5, REG_EventData
    bl SideBSweetspot_InitializePositions

SideBSweetspotThink_Exit:
    restore
    blr

################################

SideBSweetspotThink_Constants:
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

SideBSweetspot_InitializePositions:
    backup

    .set REG_P1GObj, 30
    .set REG_P1Data, 29
    .set REG_P2GObj, 28
    .set REG_P2Data, 27
    .set REG_EventData, 26
    .set LedgeSide, 20

    # Constants
    .set SideBSweet_P1X, -12
    .set SideBSweet_P1Y, 6
    .set SideBSweet_P2X, 15
    .set SideBSweet_P2Y, 0
    .set HitlagFrames, 12

    # Init Registers
    mr REG_P1GObj, r3
    lwz REG_P1Data, 0x2C(REG_P1GObj)
    mr REG_P2GObj, r4
    lwz REG_P2Data, 0x2C(REG_P2GObj)
    mr REG_EventData, r5

    # Get random side
    li r3, 2
    branchl r12, HSD_Randi
    # Backup Ledge Side
    mr LedgeSide, r3

    # Change Facing Directions
    cmpwi LedgeSide, 0x0
    beq SideBSweet_InitializePositions_GetLeftLedgeID

SideBSweet_InitializePositions_GetRightLedgeID:
    # Change Facing Direction
    li r3, -1
    bl IntToFloat
    stfs f1, 0x2C(REG_P1Data)
    li r3, 1
    bl IntToFloat
    stfs f1, 0x2C(REG_P2Data)
    b SideBSweet_InitializePositions_DirectionChangeEnd

SideBSweet_InitializePositions_GetLeftLedgeID:
    # Change Facing Direction
    li r3, 1
    bl IntToFloat
    stfs f1, 0x2C(REG_P1Data)
    li r3, -1
    bl IntToFloat
    stfs f1, 0x2C(REG_P2Data)

SideBSweet_InitializePositions_DirectionChangeEnd:
    # Get Ledge Coordinates
    mr r3, LedgeSide
    addi r4, sp, 0x80
    bl GetLedgeCoordinates

    # Move P1
    li r3, SideBSweet_P1X
    bl IntToFloat
    lfs f2, 0x80(sp)
    lfs f3, 0x2C(REG_P1Data)
    fmadds f1, f1, f3, f2
    stfs f1, 0xB0(REG_P1Data)
    li r3, SideBSweet_P1Y
    bl IntToFloat
    lfs f2, 0x84(sp)
    fadds f1, f1, f2
    stfs f1, 0xB4(REG_P1Data)
    mr r3, REG_P1GObj
    bl UpdatePosition
    # Move P2
    li r3, SideBSweet_P2X
    bl IntToFloat
    lfs f2, 0x80(sp)
    lfs f3, 0x2C(REG_P2Data)
    fneg f3, f3
    fmadds f1, f1, f3, f2
    stfs f1, 0xB0(REG_P2Data)
    li r3, SideBSweet_P2Y
    bl IntToFloat
    lfs f2, 0x84(sp)
    fadds f1, f1, f2
    stfs f1, 0xB4(REG_P2Data)
    mr r3, REG_P2GObj
    bl PlacePlayerOnGround
    # Clear P2's GFX Pointer
    li r3, 0
    stw r3, 0x60C(REG_P2Data)
    # P2 enters FSmash
    li r3, 0
    bl IntToFloat
    mr r3, REG_P2GObj
    branchl r12, 0x8008c3e0
    # Fastforward to frame 11
    li r3, 11
    bl IntToFloat
    mr r3, REG_P2GObj
    lfs f2, -0x67D8(rtoc)
    lfs f3, -0x67E4(rtoc)
    branchl r12, 0x8006ebe8
    li r3, 7
    bl IntToFloat
    stfs f1, 0x894(REG_P2Data)
    li r3, 0
    stw r3, 0x3E4(REG_P2Data)
    mr r3, REG_P2GObj
    branchl r12, 0x80073354
    # Update Animation
    mr r3, REG_P2GObj
    branchl r12, 0x8006e9b4
    # Remove all hitboxes
    mr r3, REG_P2GObj
    branchl r12, 0x8007aff8
    # Stop subaction script from being updated
    li r3, 0
    stw r3, 0x3EC(REG_P2Data)
    # Update Camera
    mr r3, REG_P2GObj
    bl UpdateCameraBox

    # P1 enters DamageFlyN
    mr r3, REG_P1GObj
    li r4, ASID_DamageFlyN
    li r5, 0x40
    li r6, 0
    lfs f1, -0x750C(rtoc)
    lfs f2, -0x7508(rtoc)
    lfs f3, -0x750C(rtoc)
    branchl r12, ActionStateChange
    # Update Animation
    mr r3, REG_P1GObj
    branchl r12, 0x8006e9b4
    # Remove Jump
    # lwz r3, 0x168(REG_P1Data)
    # stb r3, 0x1968(REG_P1Data)
    # Update Camera
    mr r3, REG_P1GObj
    bl UpdateCameraBox

    # Enter into knockback
    mr r3, REG_P1GObj
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
    lbz r3, 0xC(REG_P1Data)
    branchl r12, PlayerBlock_SetDamage

    # Reset Variables
    li r3, EventState_ThrowDelay
    stb r3, EventState(REG_EventData)
    li r3, 0
    stb r3, Timer(REG_EventData)

SideBSweetspot_InitializePositions_Exit:
    restore
    blr
