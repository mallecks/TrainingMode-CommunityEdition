###########################
## Ledge Stall HIJACK INFO ##
###########################

LedgeStall:
    # Store Match Type to READY, GO!
    li r3, 0x80
    stb r3, 0x1(r26)

    # Store Stage, CPU, and FDD Toggles
    lwz r3, 0x0(r29)                                    # Send event struct
    mr r4, r26                                          # Send match struct
    li r5, -1
    li r6, Brinstar                                     # stage
    load r7, EventOSD_LedgeStall
    li r8, 1                                            # Use Sopo bool
    bl InitializeMatch

    # 1 Player
    lwz r4, 0x0(r29)
    li r3, 0x20
    stb r3, 0x1(r4)

# STORE THINK FUNCTION
LedgeStallStoreThink:
    bl LedgeStallLoad
    mflr r3
    stw r3, 0x44(r26)                                   # on match load

    b exit

##################################
## Ledge Stall LOAD FUNCT ##
##################################
LedgeStallLoad:
    blrl

    backup

    # Schedule Think
    bl LedgeStallThink
    mflr r3
    li r4, 3                                            # Priority (After EnvCOllision)
    li r5, 0
    bl CreateEventThinkFunction

    # Destroy Lava map_gobj proc
    li r3, 8                                            # lava's map_gobj ID
    branchl r12, Stage_map_gobj_Load
    branchl r12, GObj_RemoveProc
    /*
    # Make Lava transparent
    li r3, 8                                            # lava's map_gobj ID
    branchl r12, Stage_map_gobj_Load
    li r4, 0
    branchl r12, Stage_map_gobj_LoadJObj
    li r5, 1
    lwz r4, 0x14(r3)
    rlwimi r4, r5, 29, 2, 2
    rlwimi r4, r5, 28, 3, 3
    rlwimi r4, r5, 19, 12, 12
    stw r4, 0x14(r3)
    lwz r3, 0x18(r3)
    lwz r3, 0x8(r3)
    lwz r4, 0x4(r3)
    rlwimi r4, r5, 29, 2, 2
    rlwimi r4, r5, 30, 1, 1
    stw r4, 0x4(r3)
    lwz r3, 0xC(r3)
    load r4, 0x3f000000
    stw r4, 0xC(r3)
    */
    # Get map_gobj
    li r3, 6                                            # platform's map_gobj ID
    branchl r12, Stage_map_gobj_Load
    # Get platform flesh item pointer
    lwz r3, 0x2C(r3)
    lwz r3, 0xE4(r3)
    lwz r3, 0x2C(r3)
    # Set Hurtbox as intangible
    li r4, 2
    stw r4, 0xACC(r3)

    # Create Camera Box
    branchl r12, CreateCameraBox
    mr r20, r3
    # Get Stage's Ledge IDs
    lwz r3, -0x6CB8(r13)                                # External Stage ID
    bl LedgeCliffIDs
    mflr r4
    mulli r3, r3, 0x2
    lhzx r3, r3, r4
    # Get Ledge Coordinates
    rlwinm r3, r3, 24, 24, 31
    addi r4, sp, 0xD0
    branchl r12, Stage_GetLeftOfLineCoordinates
    # Position Base of CameraBox behind the ledge
    .set CameraBoxXOffset, 35
    .set CameraBoxYOffset, 20
    li r3, CameraBoxXOffset
    bl IntToFloat
    lfs f2, 0xD0(sp)                                    # Ledge X
    fadds f1, f1, f2
    stfs f1, 0x10(r20)                                  # Camera X Position
    li r3, CameraBoxYOffset
    bl IntToFloat
    lfs f2, 0xD4(sp)                                    # Ledge Y
    fadds f1, f1, f2
    stfs f1, 0x14(r20)                                  # Camera Y Position
    # Make Boundaries around ledge position
    # Left Bound
    li r3, -10
    bl IntToFloat
    stfs f1, 0x40(r20)
    # Right Bound
    li r3, 10
    bl IntToFloat
    stfs f1, 0x44(r20)
    # Top Bound
    li r3, 10
    bl IntToFloat
    stfs f1, 0x48(r20)
    # Lower Bound
    li r3, -10
    bl IntToFloat
    stfs f1, 0x4C(r20)

    # Set Camera To Be Zoomed Out More
    load r4, 0x8049e6c8
    load r3, 0x3FE66666
    stw r3, 0x28(r4)

    b LedgeStallThink_Exit

###########################################
LedgeStallThink_Constants:
    blrl
    .set LavaRiseRate, 0x0
    .set LavaMaxY, 0x4

    .float 0.4
    .float 10

###########################################

###################################
## Ledge Stall THINK FUNCT ##
###################################

LedgeStallThink:
    blrl

    # Registers
    .set REG_EventConstants, 25
    .set REG_MenuData, 26
    .set REG_EventData, 31
    .set REG_EventGObj, 24
    .set REG_P1Data, 27
    .set REG_P1GObj, 28
    .set REG_P2Data, 29
    .set REG_P2GObj, 30

    # Event Data Offsets
    .set EventState, 0x0
    .set EventState_LavaDelay, 0x0
    .set EventState_LavaRiseThink, 0x1
    .set EventState_Reset, 0x2
    .set Timer, 0x1
    .set LavaTimer, 0x2
    .set SurvivalTime, 0x4
    .set LavaPosition, 0x8

    # Constants
    .set ResetTimer, 30
    .set LavaStartY, -100
    .set LavaStartTimer, 123
    .set SuvivalTime_CountInterval, 5

    backup

    # INIT FUNCTION VARIABLES
    mr REG_EventGObj, r3
    lwz REG_EventData, 0x2c(REG_EventGObj)              # backup data pointer in r31

    # Get Player Pointers
    bl GetAllPlayerPointers
    mr REG_P1GObj, r3
    mr REG_P1Data, r4
    mr REG_P2GObj, r5
    mr REG_P2Data, r6

    # Get Menu and Constants Pointers
    lwz REG_MenuData, REG_EventData_REG_MenuDataPointer(REG_EventData)
    bl LedgeStallThink_Constants
    mflr REG_EventConstants

    # ON FIRST FRAME
    bl CheckIfFirstFrame
    cmpwi r3, 0x0
    beq LedgeStallThink_Start
    # Init Positions
    mr r3, REG_P1GObj
    mr r4, REG_EventData
    bl LedgeStall_InitializePositions
    # Clear Inputs
    bl RemoveFirstFrameInputs
    # Save State
    addi r3, REG_EventData, EventData_SaveStateStruct
    li r4, 1                                            # Override failsafe code
    bl SaveState_Save

LedgeStallThink_Start:
    # Check if player was damaged or died
    lwz r3, 0x10(REG_P1Data)
    cmpwi r3, ASID_DamageHi1
    blt LedgeStallThink_DamageCheckSkip
    cmpwi r3, ASID_DamageFlyRoll
    bgt LedgeStallThink_DamageCheckSkip
    b LedgeStallThink_TookDamage

LedgeStallThink_DamageCheckSkip:
    lbz r3, 0x221F(REG_P1Data)
    rlwinm. r0, r3, 0, 25, 25
    beq LedgeStallThink_DeadCheckSkip

LedgeStallThink_TookDamage:
    # Check if took damage already
    lbz r3, Timer(REG_EventData)
    cmpwi r3, 0
    bgt LedgeStallThink_DeadCheckSkip
    # Set Reset Timer
    li r3, ResetTimer
    stb r3, Timer(REG_EventData)
    # Play Crowd SFX
    # li r3, 0x13D
    # bl PlaySFX
    # Advance State
    li r3, EventState_Reset
    stb r3, EventState(REG_EventData)

LedgeStallThink_DeadCheckSkip:
LedgeStallThink_SwitchCase:
    # Switch Case
    lbz r3, EventState(REG_EventData)
    cmpwi r3, EventState_LavaDelay
    beq LedgeStallThink_LavaDelay
    cmpwi r3, EventState_LavaRiseThink
    beq LedgeStallThink_LavaRiseThink
    cmpwi r3, EventState_Reset
    beq LedgeStallThink_Reset
    b LedgeStallThink_CheckTimer

LedgeStallThink_LavaDelay:
    # Reset Timer back to 0
    li r3, 0
    load r4, 0x8046b6a0
    stw r3, 0x28(r4)                                    # seconds
    sth r3, 0x2C(r4)                                    # subseconds

    # Decrement Lava Timer
    lhz r3, LavaTimer(REG_EventData)
    subi r3, r3, 1
    sth r3, LavaTimer(REG_EventData)
    # Check if up
    cmpwi r3, 0
    bgt LedgeStallThink_CheckTimer
    # Advance State
    li r3, EventState_LavaRiseThink
    stb r3, EventState(REG_EventData)
    b LedgeStallThink_LavaRiseThink

LedgeStallThink_LavaRiseThink:
    # Ensure player is in the lava before incrementing survival time
    lfs f1, LavaPosition(REG_EventData)
    lfs f2, 0xB4(REG_P1Data)
    fcmpo cr0, f2, f1
    bge LedgeStallThink_LavaRiseThink_NotInLava
    # Increment Score
    lwz r3, SurvivalTime(REG_EventData)
    addi r3, r3, 1
    stw r3, SurvivalTime(REG_EventData)

LedgeStallThink_LavaRiseThink_SkipScoreIncrement:
    # Play HRC SFX every X score
    li r3, SuvivalTime_CountInterval
    bl IntToFloat
    fmr f2, f1
    lwz r3, SurvivalTime(REG_EventData)
    subi r3, r3, 1
    bl IntToFloat
    branchl r12, fmod
    fmr f2, f1
    li r3, 0
    bl IntToFloat
    fcmpo cr0, f2, f1
    bne LedgeStallThink_LavaRiseThink_SkipSFX
    # Play SFX
    li r3, 0xBB
    bl PlaySFX
    li r3, 0xBB
    bl PlaySFX

LedgeStallThink_LavaRiseThink_SkipSFX:
    b LedgeStallThink_LavaRiseThink_NotInLavaSkip

LedgeStallThink_LavaRiseThink_NotInLava:
    # Reset Timer back to 0
    li r3, 0
    load r4, 0x8046b6a0
    stw r3, 0x28(r4)                                    # seconds
    sth r3, 0x2C(r4)                                    # subseconds
    # Set survival time to 0
    stw r3, SurvivalTime(REG_EventData)

LedgeStallThink_LavaRiseThink_NotInLavaSkip:
    # Check if lava is at max height
    lfs f1, LavaPosition(REG_EventData)
    lfs f2, LavaMaxY(REG_EventConstants)
    fcmpo cr0, f1, f2
    bge LedgeStallThink_LavaRiseThink_SkipLavaRise
    # Raise Lava
    lfs f2, LavaRiseRate(REG_EventConstants)
    fadds f1, f1, f2
    stfs f1, LavaPosition(REG_EventData)
    bl Ledgestall_UpdateLavaPosition

LedgeStallThink_LavaRiseThink_SkipLavaRise:
    b LedgeStallThink_CheckTimer

LedgeStallThink_Reset:
    # Effectively pause timer
    load r4, 0x8046b6a0
    lwz r3, 0x28(r4)                                    # seconds
    cmpwi r3, 0
    beq LedgeStallThink_NoSecondCarryover
    lhz r3, 0x2C(r4)                                    # subseconds
    cmpwi r3, 0
    bne LedgeStallThink_NoSecondCarryover
    li r3, 0x3B
    sth r3, 0x2C(r4)                                    # subseconds
    lwz r3, 0x28(r4)                                    # seconds
    subi r3, r3, 1
    stw r3, 0x28(r4)                                    # seconds
    b LedgeStallThink_CheckTimer

LedgeStallThink_NoSecondCarryover:
    lhz r3, 0x2C(r4)                                    # subseconds
    subi r3, r3, 1
    sth r3, 0x2C(r4)                                    # subseconds
    b LedgeStallThink_CheckTimer

LedgeStallThink_CheckTimer:
    # Check if timer exists
    lbz r3, Timer(REG_EventData)
    cmpwi r3, 0
    ble LedgeStallThink_Exit
    # Decrement timer
    subi r3, r3, 1
    stb r3, Timer(REG_EventData)
    cmpwi r3, 0
    bgt LedgeStallThink_Exit

    # Pasue game
    lfs f1, -0x4D68(rtoc)
    branchl r12, 0x8016b274                             # Pause game engine
    # Check if player had any score when taking damage
    lwz r3, SurvivalTime(REG_EventData)
    cmpwi r3, 0
    ble LedgeStallThink_Failure

LedgeStallThink_Success:
    # Get current high score
    lwz r3, MemcardData(r13)
    lbz r20, 0x535(r3)
    mr r3, r20
    branchl r12, Events_GetEventSavedScore
    lwz r4, SurvivalTime(REG_EventData)
    cmpw r4, r3
    ble LedgeStallThink_Success_NoHighScore

LedgeStallThink_Success_NewHighScore:
    li r3, 2
    branchl r12, 0x8016b33c                             # Display Success + SFX
    load r3, 0x9c40
    branchl r12, 0x8016b350
    li r3, 325
    branchl r12, 0x8016b364                             # queue crowd cheer after Success
    branchl r12, 0x8016b328                             # set game as ended
    mr r3, r20                                          # update score
    lwz r4, SurvivalTime(REG_EventData)
    branchl r12, Events_SetEventSavedScore
    mr r3, r20                                          # set event as played
    branchl r12, 0x8015ceb4
    b LedgeStallThink_Success_DestroyGObj

LedgeStallThink_Success_NoHighScore:
    li r3, 2
    branchl r12, 0x8016b33c                             # Display New Record + SFX
    li r3, 324
    branchl r12, 0x8016b364                             # queue crowd cheer after New Record
    branchl r12, 0x8016b328                             # set game as ended
    b LedgeStallThink_Success_DestroyGObj

LedgeStallThink_Failure:
    li r3, 6
    branchl r12, 0x8016b33c                             # Display Failure + SFX
    li r3, 328
    branchl r12, 0x8016b364                             # queue crowd sigh after failure
    li r3, 40
    branchl r12, 0x8016b378                             # frames to linger?
    branchl r12, 0x8016b328                             # set game as ended
    b LedgeStallThink_Success_DestroyGObj

LedgeStallThink_Success_DestroyGObj:
    mr r3, REG_EventGObj
    branchl r12, GObj_Destroy                           # destroy event gobj
    b LedgeStallThink_Exit

LedgeStallThink_Restore:
    # Restore State
    addi r3, REG_EventData, EventData_SaveStateStruct
    li r4, 1
    bl SaveState_Load
    # Init Positions Again
    mr r3, REG_P1GObj
    mr r4, REG_EventData
    bl LedgeStall_InitializePositions
    # Enable Inputs
    lbz r3, 0x221D(REG_P1Data)
    li r4, 0
    rlwimi r3, r4, 3, 28, 28
    stb r3, 0x221D(REG_P1Data)
    # Shorten Timer
    li r3, 0
    sth r3, LavaTimer(REG_EventData)

LedgeStallThink_Exit:
    restore
    blr

################################

LedgeStall_InitializePositions:
    backup

    .set REG_P1GObj, 30
    .set REG_P1Data, 29
    .set REG_EventData, 28
    .set REG_map_gobj, 27
    .set REG_map_gobj_JObj, 26

    # Init Registers
    mr REG_P1GObj, r3
    lwz REG_P1Data, 0x2C(REG_P1GObj)
    mr REG_EventData, r4

    # Place on left ledge
    mr r3, REG_P1GObj
    li r4, 0
    bl PlaceOnLedge

    # Update Camera
    mr r3, REG_P1GObj
    bl UpdateCameraBox

    # Init Lava Y
    li r3, LavaStartY
    bl IntToFloat
    stfs f1, LavaPosition(REG_EventData)
    bl Ledgestall_UpdateLavaPosition

    # Reset Variables
    li r3, EventState_LavaDelay
    stb r3, EventState(REG_EventData)
    li r3, 0
    stb r3, Timer(REG_EventData)
    stw r3, SurvivalTime(REG_EventData)

    # Init Lava Start Timer
    li r3, LavaStartTimer
    sth r3, LavaTimer(REG_EventData)

LedgeStall_InitializePositions_Exit:
    restore
    blr

#####################################
Ledgestall_UpdateLavaPosition:
    backup

    .set REG_LavaY, 31
    .set REG_map_gobj_JObj, 30

    # Backup args
    stfs f1, 0x80(sp)

    # Get Lava map_gobj
    li r3, 8                                            # lava's map_gobj ID
    branchl r12, Stage_map_gobj_Load
    # Get JObj
    li r4, 0
    branchl r12, Stage_map_gobj_LoadJObj
    mr REG_map_gobj_JObj, r3

    # Get 55f (jobj doesnt line up with actual position)
    li r3, 55
    bl IntToFloat
    # Update JObj Y position
    lfs f2, 0x80(sp)
    fadds f1, f1, f2
    stfs f1, 0x3C(REG_map_gobj_JObj)
    # DirtySub
    mr r3, REG_map_gobj_JObj
    branchl r12, HSD_JObjSetMtxDirtySub

    # Adjust hitbox position
    lfs f1, 0x80(sp)
    branchl r12, 0x801c438c

Ledgestall_UpdateLavaPosition_Exit:
    restore
    blr
