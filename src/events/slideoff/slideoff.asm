###########################
## Slide Off HIJACK INFO ##
###########################

SlideOff:
    # Store Stage, CPU, and FDD Toggles
    lwz r3, 0x0(r29)                                    # Send event struct
    mr r4, r26                                          # Send match struct
    li r5, Marth.Ext
    li r6, PokemonStadium                               # Use chosen Stage
    load r7, EventOSD_SlideOff
    li r8, 1                                            # Use Sopo bool
    bl InitializeMatch

# STORE THINK FUNCTION
SlideOffStoreThink:
    bl SlideOffLoad
    mflr r3
    stw r3, 0x44(r26)                                   # on match load

    b exit

##################################
## Slide Off LOAD FUNCT ##
##################################
SlideOffLoad:
    blrl

    backup

    # Schedule Think
    bl SlideOffThink
    mflr r3
    li r4, 3                                            # Priority (After EnvCOllision)
    li r5, 0
    bl CreateEventThinkFunction
    b SlideOffThink_Exit

###################################
## Slide Off THINK FUNCT ##
###################################

SlideOffThink:
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
    .set EventState_DetermineAttack, 0x1
    .set EventState_AttackThink, 0x2
    .set EventState_Shield, 0x3
    .set Timer, 0x1
    .set P1State, 0x2
    .set P1State_Wait, 0x0
    .set P1State_Attacking, 0x1
    .set AttackTimer, 0x3

    # Constants
    .set ResetTimer, 40
    .set AngleLo, 83
    .set AngleHi, 100
    .set MagLo, 65
    .set MagHi, 75
    .set HitlagFrames, 12
    .set PercentLo, 40
    .set PercentHi, 40
    .set FramesBeforeHitbox, 7

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
    bl SlideOffThink_Constants
    mflr REG_EventConstants

    bl StoreCPUTypeAndZeroInputs

    # ON FIRST FRAME
    bl CheckIfFirstFrame
    cmpwi r3, 0x0
    beq SlideOffThink_Start
    # Init Positions
    mr r3, REG_P1GObj
    mr r4, REG_P2GObj
    bl SlideOff_InitializePositions
    # Clear Inputs
    bl RemoveFirstFrameInputs
    # Save State
    addi r3, REG_EventData, EventData_SaveStateStruct
    li r4, 1                                            # Override failsafe code
    bl SaveState_Save
    # Init State
    li r3, EventState_Hitstun
    stb r3, EventState(REG_EventData)

SlideOffThink_Start:
    # Reset if anyone died
    bl IsAnyoneDead
    cmpwi r3, 0
    bne SlideOffThink_Restore

SlideOffThink_CheckIfFailed:
    # Check if failed the slide off (in non-hitlag damage state)
    # EventState > EventState_Hitstun
    lbz r3, EventState(REG_EventData)
    cmpwi r3, EventState_Hitstun
    ble SlideOffThink_CheckIfFailed_End
    # Check for hitlag
    lbz r3, 0x221A(REG_P1Data)
    rlwinm. r3, r3, 0, 26, 26
    bne SlideOffThink_CheckIfFailed_End
    # Check if in hitstun
    lbz r3, 0x221C(REG_P1Data)
    rlwinm. r3, r3, 0, 30, 30
    beq SlideOffThink_CheckIfFailed_End
    # Check if player has been in this state for over 5 frames
    lhz r3, TM_FramesinCurrentAS(REG_P1Data)
    cmpwi r3, 5
    blt SlideOffThink_CheckIfFailed_End
    # Check if timer has started
    lbz r3, Timer(REG_EventData)
    cmpwi r3, 0
    bgt SlideOffThink_CheckTimer
    # Start Timer
    li r3, 10
    stb r3, Timer(REG_EventData)

SlideOffThink_CheckIfFailed_End:
SlideOffThink_CheckIfCPUDamaged:
    lwz r3, 0x10(REG_P2Data)
    cmpwi r3, ASID_DamageHi1
    blt SlideOffThink_CheckIfCPUDamaged_End
    cmpwi r3, ASID_DamageFlyRoll
    bgt SlideOffThink_CheckIfCPUDamaged_End
    # Check if timer has started
    lbz r3, Timer(REG_EventData)
    cmpwi r3, 0
    bgt SlideOffThink_CheckIfCPUDamaged_End
    # Start Timer
    li r3, ResetTimer
    stb r3, Timer(REG_EventData)

SlideOffThink_CheckIfCPUDamaged_End:
SlideOffThink_SwitchCase:
    # Switch Case
    lbz r3, EventState(REG_EventData)
    cmpwi r3, EventState_Hitstun
    beq SlideOffThink_Hitstun
    cmpwi r3, EventState_DetermineAttack
    beq SlideOffThink_DetermineAttackorShield
    cmpwi r3, EventState_AttackThink
    beq SlideOffThink_AttackThink
    cmpwi r3, EventState_Shield
    beq SlideOffThink_Shield
    b SlideOffThink_CheckTimer

SlideOffThink_Hitstun:
    # Check if still in ThrowHi
    lwz r3, 0x10(REG_P2Data)
    cmpwi r3, ASID_ThrowHi
    beq SlideOffThink_CheckTimer

    # Check if P1 is in a tech/mistech state
    lwz r3, 0x10(REG_P1Data)
    cmpwi r3, ASID_DownBoundU
    blt SlideOffThink_CheckTimer
    cmpwi r3, ASID_PassiveStandB
    bgt SlideOffThink_CheckTimer

    # Change state to attack
    li r3, EventState_DetermineAttack
    stb r3, EventState(EventData)
    b SlideOffThink_CheckTimer

SlideOffThink_DetermineAttackorShield:
    /*
    # Ensure facing correct direction
    # Get Values
    lfs f1, 0xB0(REG_P2Data)                            # p2 position
    lfs f2, 0x2C(REG_P2Data)                            # p2 direction
    lfs f4, TriggerBoxXMin(REG_EventConstants)
    lfs f5, TriggerBoxXMax(REG_EventConstants)
    lfs f6, 0xB0(REG_P1Data)
    # Check X
    fmadds f3, f2, f4, f1                               # XMin
    fmadds f4, f2, f5, f1                               # XMax
    # Make sure player is not behind marths range
    lfs f1, -0x68E0(rtoc)                               # fp 0
    fcmpo cr0, f2, f1
    bge SlideOffThink_Attck_FacingRight

SlideOffThink_Attck_FacingLeft:
    li r3, 1
    fcmpo cr0, f6, f3
    bge SlideOffThink_Attck_InputTurn
    b SlideOffThink_Attck_SkipDirectionChange

SlideOffThink_Attck_FacingRight:
    li r3, -1
    fcmpo cr0, f6, f3
    ble SlideOffThink_Attck_InputTurn
    b SlideOffThink_Attck_SkipDirectionChange

SlideOffThink_Attck_InputTurn:
    # Check if already turning
    lwz r4, 0x10(REG_P2Data)
    cmpwi r4, ASID_Turn
    beq SlideOffThink_Attck_SkipDirectionChange
    # Input turn
    mulli r3, r3, 36
    stb r3, CPU_AnalogX(REG_P2Data)

SlideOffThink_Attck_SkipDirectionChange:
    */

SlideOffThink_DetermineAttackorShield_SkipFailCheck:
    # Decide to shield or attack
    lfs f1, 0xB4(REG_P2Data)                            # p2 position
    lfs f2, TriggerBoxYMin(REG_EventConstants)
    lfs f3, TriggerBoxYMax(REG_EventConstants)
    lfs f4, 0xB4(REG_P1Data)                            # p1 position
    fadds f2, f1, f2                                    # YMin
    fadds f3, f1, f3                                    # YMax
    # Check if P1 is above YMax
    fcmpo cr0, f4, f3
    bge SlideOffThink_DetermineAttackorShield_AboveTriggerBox
    # Check if P1 is below YMin
    fcmpo cr0, f4, f2
    bge SlideOffThink_DetermineAttackorShield_CheckToAttack_CanAttack

SlideOffThink_DetermineAttackorShield_EnterShield:
    # Change Event State
    li r3, EventState_Shield
    stb r3, EventState(REG_EventData)
    # Start Timer
    li r3, ResetTimer
    stb r3, Timer(REG_EventData)
    b SlideOffThink_Shield

SlideOffThink_DetermineAttackorShield_AboveTriggerBox:
    # Check if timer has started
    lbz r3, Timer(REG_EventData)
    cmpwi r3, 0
    bgt SlideOffThink_CheckTimer
    # Start Timer
    li r3, 10
    stb r3, Timer(REG_EventData)
    b SlideOffThink_CheckTimer

SlideOffThink_DetermineAttackorShield_CheckToAttack_CanAttack:
    # Get P1's State
    lwz r3, 0x10(REG_P1Data)
    # Ensure we have the frame data for this state
    cmpwi r3, ASID_DownBoundU
    blt SlideOffThink_DetermineAttackorShield_CheckToAttack_StartAttack
    cmpwi r3, ASID_PassiveStandB
    bgt SlideOffThink_DetermineAttackorShield_CheckToAttack_StartAttack
    # If DownWait or Bound, dont do anything
    cmpwi r3, ASID_DownWaitD
    beq SlideOffThink_DetermineAttackorShield_CheckToAttackEnd
    cmpwi r3, ASID_DownWaitU
    beq SlideOffThink_DetermineAttackorShield_CheckToAttackEnd
    cmpwi r3, ASID_DownBoundD
    beq SlideOffThink_DetermineAttackorShield_CheckToAttackEnd
    cmpwi r3, ASID_DownBoundU
    beq SlideOffThink_DetermineAttackorShield_CheckToAttackEnd
    # Get the frame data to use
    subi r3, r3, ASID_DownBoundU
    addi r4, REG_EventConstants, VulnFrameData
    lbzx r3, r3, r4
    # Marth takes 8 frames for his utilt hitbox to appear, so subtract 8
    subi r3, r3, FramesBeforeHitbox
    # Use the custom playerblock offset to check P1's frame count
    lhz r4, TM_FramesinCurrentAS(REG_P1Data)
    cmpw r4, r3
    blt SlideOffThink_DetermineAttackorShield_CheckToAttackEnd

# Time to attack
SlideOffThink_DetermineAttackorShield_CheckToAttack_StartAttack:
    li r3, EventState_AttackThink
    stb r3, EventState(REG_EventData)
    b SlideOffThink_DetermineAttackorShield_CheckToAttackEnd

SlideOffThink_DetermineAttackorShield_CheckToAttackEnd:
    b SlideOffThink_CheckTimer

SlideOffThink_AttackThink:
    # Get Inputs for this frame
    mr r3, REG_P2Data
    bl SlideOffThink_AttackInputs
    mflr r4
    lbz r5, AttackTimer(REG_EventData)
    bl PlaybackInputSequence

    # Always succeed LCancel
    li r3, 0
    stb r3, 0x67F(REG_P2Data)

    # Remove Hitbox ID 1, 2 and 3(problematic for getting slideoff)
    mr r3, REG_P2GObj
    li r4, 1
    branchl r12, 0x8007afc8
    mr r3, REG_P2GObj
    li r4, 2
    branchl r12, 0x8007afc8
    mr r3, REG_P2GObj
    li r4, 3
    branchl r12, 0x8007afc8

    # Exit AttackThink when returning to Wait
    lbz r3, AttackTimer(REG_EventData)
    cmpwi r3, 0
    ble SlideOffThink_AttackThink_Exit
    lwz r3, 0x10(REG_P2Data)
    cmpwi r3, ASID_Wait
    beq SlideOffThink_AttackThink_Reset
    cmpwi r3, ASID_Landing
    bne SlideOffThink_AttackThink_Exit
    # Now check if interruptable
    lwz r3, 0x2340(REG_P2Data)
    cmpwi r3, 0
    beq SlideOffThink_AttackThink_Exit
    # Check if this frame is interruptable
    lfs f1, 0x1f4(REG_P2Data)
    fctiwz f1, f1
    stfd f1, 0x80(sp)
    lwz r3, 0x84(sp)
    lhz r4, TM_FramesinCurrentAS(REG_P2Data)
    cmpw r4, r3
    blt SlideOffThink_AttackThink_Exit

SlideOffThink_AttackThink_Reset:
    li r3, EventState_DetermineAttack                   # event state
    stb r3, EventState(REG_EventData)
    li r3, 0                                            # reset timer
    stb r3, AttackTimer(REG_EventData)
    b SlideOffThink_CheckTimer

SlideOffThink_AttackThink_Exit:
    # Check if in Hitlag
    lbz r3, 0x221A(REG_P2Data)
    rlwinm. r3, r3, 0, 26, 26
    bne SlideOffThink_CheckTimer
    # Increment Attack Timer
    lbz r3, AttackTimer(REG_EventData)
    addi r3, r3, 1
    stb r3, AttackTimer(REG_EventData)
    b SlideOffThink_CheckTimer

SlideOffThink_Shield:
    # Hold Shield
    li r3, PAD_TRIGGER_R
    stw r3, CPU_HeldButtons(REG_P2Data)
    b SlideOffThink_CheckTimer

SlideOffThink_CheckTimer:
    # Check if timer exists
    lbz r3, Timer(REG_EventData)
    cmpwi r3, 0
    ble SlideOffThink_Exit
    # Decrement timer
    subi r3, r3, 1
    stb r3, Timer(REG_EventData)
    cmpwi r3, 0
    bgt SlideOffThink_Exit

SlideOffThink_Restore:
    # Restore State
    addi r3, REG_EventData, EventData_SaveStateStruct
    li r4, 1
    bl SaveState_Load
    # Init Positions Again
    mr r3, REG_P1GObj
    mr r4, REG_P2GObj
    bl SlideOff_InitializePositions
    # Reset Variables
    li r3, 0
    stb r3, EventState(REG_EventData)
    stb r3, Timer(REG_EventData)
    stb r3, P1State(REG_EventData)
    stb r3, AttackTimer(REG_EventData)

SlideOffThink_Exit:
    restore
    blr

################################

SlideOffThink_Constants:
    blrl
    .set MarthUTiltFrame, 8
    .set P1X, 0x0
    .set P1Y, 0x4
    .set P2X, 0x8
    .set P2Y, 0xC
    .set UThrowStartFrame, 0x10
    .set DamageFlyTopStartFrame, 0x14
    .set MagnitudeScalar, 0x18
    .set MagnitudeScalar2, 0x1C
    .set MagnitudeScalar3, 0x20
    .set TriggerBoxXMin, 0x24
    .set TriggerBoxXMax, 0x28
    .set TriggerBoxYMin, 0x2C
    .set TriggerBoxYMax, 0x30
    .set VulnFrameData, 0x34
    .set Unk, 0x48

    .float -37.7                                        # p1 x
    .float 21.2                                         # p1 y
    .float -41.1                                        # p2 x
    .float 0                                            # p2 y
    .float 13                                           # marth upthrow starting frame
    .float 2                                            # p1 damageflytop starting frame
    .float 0.1                                          # baseline for mag scaling
    .float 1                                            # mag scaling constant
    .float 0.4                                          # mag scaling constant
    .float -8                                           # xmin
    .float 20                                           # xmax
    .float 18                                           # ymin
    .float 30                                           # ymax
    ##########################################
    .set TechVuln, 24-4
    .set TechRollVuln, 23
    .set KnockdownVuln, 23
    .set GetupVuln, 23
    .set GetupRollForwardVuln, 20-1
    .set GetupRollBackwardVuln, 30-3
    .set GetupAttackVuln, 27

    .byte KnockdownVuln                                 # DownBoundU
    .byte 0                                             # DownWaitU
    .byte 0                                             # DownDamageU
    .byte GetupVuln                                     # DownStandU
    .byte GetupAttackVuln                               # DownAttackU
    .byte GetupRollForwardVuln                          # DownForwardU
    .byte GetupRollBackwardVuln                         # DownBackU
    .byte -1                                            # DownSpotU (unused state)
    .byte KnockdownVuln                                 # DownBoundD
    .byte 0                                             # DownWaitD
    .byte 0                                             # DownDamageD
    .byte GetupVuln                                     # DownStandD
    .byte GetupAttackVuln                               # DownAttackD
    .byte GetupRollForwardVuln                          # DownForwardD
    .byte GetupRollBackwardVuln                         # DownBackD
    .byte -1                                            # DownSpotD(unused state)
    .byte TechVuln                                      # Passive
    .byte TechRollVuln                                  # PassiveStandF
    .byte TechRollVuln                                  # PassiveStandB
    .align 2

###########################################
SlideOffThink_AttackInputs:
    blrl
    .byte 0
    .long PAD_BUTTON_X
    .byte 0, 0, 0, 0

    .byte 4
    .long 0
    .byte 0, 0, 0, 127

    .byte 26
    .long PAD_TRIGGER_L
    .byte 0, -127, 0, 0

    .byte -1
    .align 2

#################################

SlideOff_InitializePositions:
    backup

    # Change Facing Direction
    li r3, -1
    bl IntToFloat
    stfs f1, 0x2C(REG_P1Data)
    li r3, 1
    bl IntToFloat
    stfs f1, 0x2C(REG_P2Data)

    # Get Starting Coordinates
    lfs f1, P1X(REG_EventConstants)
    stfs f1, 0xB0(REG_P1Data)
    lfs f1, P1Y(REG_EventConstants)
    stfs f1, 0xB4(REG_P1Data)
    mr r3, REG_P1GObj
    bl UpdatePosition
    mr r3, REG_P1GObj
    bl UpdateCameraBox

    lfs f1, P2X(REG_EventConstants)
    stfs f1, 0xB0(REG_P2Data)
    lfs f1, P2Y(REG_EventConstants)
    stfs f1, 0xB4(REG_P2Data)
    mr r3, REG_P2GObj
    bl PlacePlayerOnGround
    mr r3, REG_P2GObj
    bl UpdateCameraBox

    # P2 enters UpThrow
    mr r3, REG_P2GObj
    li r4, ASID_ThrowHi
    li r5, 0
    li r6, 0
    lwz r7, 0x10C(REG_P1Data)                           # determine speed from weight
    lwz r7, 0x0(r7)
    lfs f1, 0x88(r7)
    lfs f2, -0x68DC(rtoc)
    lwz r7, -0x514C(r13)
    lfs f0, 0x037C(r7)
    fmuls f0, f1, f0
    fdivs f2, f2, f0                                    # anim speed
    lfs f3, -0x68E0(rtoc)                               # frame blend
    lfs f1, UThrowStartFrame(REG_EventConstants)        # starting frame
    branchl r12, ActionStateChange

    # P1 enters DamageFlyTop
    mr r3, REG_P1GObj
    li r4, ASID_DamageFlyTop
    li r5, 0x40
    li r6, 0
    lfs f1, DamageFlyTopStartFrame (REG_EventConstants)
    lfs f2, -0x73D0(rtoc)
    lfs f3, -0x750C(rtoc)
    branchl r12, ActionStateChange

    # Scale KB Magnitude based on characters weight
    li r3, MagLo
    bl IntToFloat
    lfs f2, MagnitudeScalar(REG_EventConstants)
    lfs f3, 0x16C(REG_P1Data)
    lfs f4, MagnitudeScalar2(REG_EventConstants)
    lfs f5, MagnitudeScalar3(REG_EventConstants)
    fdivs f2, f3, f2
    fsubs f2, f2, f4
    fmuls f2, f2, f5
    fmuls f2, f2, f1
    fadds f1, f1, f2
    fctiwz f1, f1
    stfd f1, 0x80(sp)
    lwz r20, 0x84(sp)

    li r3, MagHi
    bl IntToFloat
    lfs f2, MagnitudeScalar(REG_EventConstants)
    lfs f3, 0x16C(REG_P1Data)
    lfs f4, MagnitudeScalar2(REG_EventConstants)
    lfs f5, MagnitudeScalar3(REG_EventConstants)
    fdivs f2, f3, f2
    fsubs f2, f2, f4
    fmuls f2, f2, f5
    fmuls f2, f2, f1
    fadds f1, f1, f2
    fctiwz f1, f1
    stfd f1, 0x80(sp)
    lwz r21, 0x84(sp)

    # Enter into knockback
    mr r3, REG_P1GObj
    li r4, AngleLo
    li r5, AngleHi
    mr r6, r20
    mr r7, r21
    bl EnterKnockback

    # Override hitstun amount
    li r3, 50
    bl IntToFloat
    stfs f1, 0x2340(REG_P1Data)

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

    # Random percent between 10-25
    li r3, PercentHi-PercentLo
    branchl r12, HSD_Randi
    addi r4, r3, PercentLo
    lbz r3, 0xC(REG_P1Data)
    branchl r12, PlayerBlock_SetDamage

SlideOff_InitializePositions_Exit:
    restore
    blr
