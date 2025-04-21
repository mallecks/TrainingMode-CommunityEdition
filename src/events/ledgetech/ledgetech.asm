#########################
## Ledgetech HIJACK INFO ##
#########################

Ledgetech:
    # Store Stage, CPU, and FDD Toggles
    lwz r3, 0x0(r29)                                    # Send event struct
    mr r4, r26                                          # Send match struct
    li r5, Falco.Ext                                    # Use chosen CPU
    li r6, -1                                           # Use chosen Stage
    load r7, EventOSD_LedgeTech
    li r8, 1                                            # Use Sopo bool
    bl InitializeMatch

    # BUFF DEFENSE RATIO
    lis r3, 0x3f00
    stw r3, 0x14(r20)

# STORE THINK FUNCTION
LedgetechStoreThink:
    bl LedgetechLoad
    mflr r3
    stw r3, 0x44(r26)                                   # on match load

    b exit

########################
## Ledgetech LOAD FUNCT ##
########################
LedgetechLoad:
    blrl

    backup

    bl InitializeHighScore

    # Schedule Think
    bl LedgetechThink
    mflr r3
    li r4, 3                                            # Priority (After Interrupt)
    li r5, 0                                            # No Option Menu
    bl CreateEventThinkFunction

    b LedgetechLoadExit

#########################
## Ledgetech THINK FUNCT ##
#########################

LedgetechThink:
    blrl

    .set P1Data, 27
    .set P1GObj, 28
    .set P2Data, 29
    .set P2GObj, 30
    .set EventData, 31

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
    beq LedgetechThinkMain

    # Clear Inputs
    bl RemoveFirstFrameInputs
    # Random Side of Stage
    li r3, 2
    branchl r12, HSD_Randi
    bl Ledgetech_InitializePositions
    # Enter SquatWait
    mr r3, P2GObj
    branchl r12, AS_SquatWait
    # P1 Has 90%
    li r3, 90
    load r4, 0x80453080                                 # P1 Static Block
    sth r3, 0x60(r4)                                    # Store Percent Int To Display Value
    lis r3, 0x42B4
    stw r3, 0x1830(r27)
    # Always Hold Down (Crouch Cancel)
    li r3, -127
    stb r3, 0x1A8D(P2Data)
    # Save State
    addi r3, EventData, EventData_SaveStateStruct
    li r4, 1                                            # Override failsafe
    bl SaveState_Save

LedgetechThinkMain:
    bl GiveFullShields

LedgetechThinkSequence:
    # Get Floats
    bl Ledgetech_Floats
    mflr r21

    # Reset if P1 Is In a Dead State
    lbz r3, 0x221F(r27)
    rlwinm. r3, r3, 0, 25, 25
    bne LedgetechRestoreState

    # D-Pad Left Restores State
    lwz r3, 0x668(r27)
    rlwinm. r0, r3, 0, 31, 31
    bne LedgetechRestoreState

    # Always Hold Down (Crouch Cancel)
    li r3, -127
    stb r3, 0x1A8D(r29)

    # Start Timer When Leaving Rebirth Plat
    lbz r3, 0x8(r31)                                    # Check If Left Plat Already
    cmpwi r3, 0x0
    bne LedgetechSkipTimerStart
    lwz r3, 0x10(r27)
    cmpwi r3, 0xD
    beq LedgetechIncreaseRespawnPlatTime
    # Set Flag
    li r3, 0x1
    stb r3, 0x8(r31)
    # Remove Invinc
    li r3, 0x0
    stw r3, 0x198C(r27)
    stw r3, 0x1990(r27)
    stw r3, 0x1994(r27)
    mr r3, r28
    branchl r12, GFX_RemoveAll
    # Set Timer
    li r3, 180
    stw r3, 0x4(r31)
    b LedgetechSkipTimerStart

LedgetechIncreaseRespawnPlatTime:
    li r3, 0x2
    stw r3, 0x2340(r27)

LedgetechSkipTimerStart:
    # Freeze Falco On Frame X
    lwz r3, 0x10(r29)
    cmpwi r3, 0x40
    bne LedgetechSkipFalcoFreze
    li r3, 0x6
    bl IntToFloat
    lfs f2, 0x894(r29)
    fcmpo cr0, f1, f2
    bne LedgetechSkipFalcoFreze
    li r3, 0
    bl IntToFloat
    mr r3, r30
    branchl r12, FrameSpeedChange

LedgetechSkipFalcoFreze:
    # If Player 1 Ledge Tech's, Set Timer to 2 Seconds
    # Check Gatekeeper Flag
    lbz r3, 0xA(r31)
    cmpwi r3, 0x1
    beq Ledgetech_UpdateLedgetechFlags

    # Check For Tech
    lwz r3, 0x10(r27)
    cmpwi r3, 0xCA
    beq LedgetechWallTeched
    cmpwi r3, 0xCB
    beq LedgetechWallTeched
    b Ledgetech_UpdateLedgetechFlags

LedgetechWallTeched:
    # Extend Timer
    li r3, 180
    stw r3, 0x4(r31)
    # Set Tech Bool
    li r3, 1
    stb r3, 0x9(r31)
    # Set Gatekeeper Flag
    li r3, 1
    stb r3, 0xA(r31)

Ledgetech_UpdateLedgetechFlags:
    # Check If Still Ledgeteching
    lwz r3, 0x10(r27)
    cmpwi r3, 0xCA
    beq LedgetechUpdateScore
    cmpwi r3, 0xCB
    beq LedgetechUpdateScore
    # Not Ledgeteching, Remove Gatekeeper Flag
    li r3, 0
    stb r3, 0xA(r31)
    b LedgetechUpdateScoreHUD

LedgetechUpdateScore:
    # Check To Increment Score
    # Check Ledgetech Bool
    lbz r3, 0x9(r31)
    cmpwi r3, 0x1
    bne LedgetechUpdateScoreHUD
    # Reset LedgeTech Bool
    li r3, 0
    stb r3, 0x9(r31)
    # Increment Score
    lhz r3, -0x4ea8(r13)
    addi r3, r3, 0x1
    sth r3, -0x4ea8(r13)
    # Check To Make New High Score
    lhz r3, -0x4ea8(r13)
    lhz r4, -0x4ea6(r13)
    cmpw r3, r4
    ble LedgetechUpdateScoreHUD
    # Copy To High Score
    sth r3, -0x4ea6(r13)

LedgetechUpdateScoreHUD:
    # Update HUD Score
    lhz r3, -0x4ea8(r13)
    branchl r12, HUD_KOCounter_UpdateKOs

    # Unfreeze Falco On Hit
    li r3, 0x0
    bl IntToFloat
    lfs f2, 0x89C(r29)
    fcmpo cr0, f1, f2
    bne LedgetechSkipFalcoUnfreeze
    lwz r3, 0x988(r29)
    cmpwi r3, 0x0
    beq LedgetechSkipFalcoUnfreeze
    li r3, 1
    bl IntToFloat
    mr r3, r30
    branchl r12, FrameSpeedChange

LedgetechSkipFalcoUnfreeze:
LedgetechCheckIfCrouching:
    # Only Attempt to DSmash in Squat and SquatWait
    lwz r3, 0x10(r29)
    cmpwi r3, 0x27
    beq LedgetechCheckDistance
    cmpwi r3, 0x28
    beq LedgetechCheckDistance
    b LedgetechCheckToReset

LedgetechCheckDistance:
    # Distance Formula (Get Distance in f1)
    addi r3, r29, 0xB0                                  # P2 Positon
    addi r4, r27, 0xB0                                  # P1 Position
    bl GetDistance
    lfs f2, 0x0(r21)
    fcmpo cr0, f1, f2
    bgt LedgetechCheckToReset
    # Enter DSmash
    li r3, -127
    stb r3, 0x1A8F(r29)
    # Initiate Reset Timer
    lwz r3, 0x4(r31)                                    # Get Timer
    cmpwi r3, 0x0                                       # If Already Set, Skip
    bne LedgetechCheckToReset
    li r3, 60
    stw r3, 0x4(r31)

# Check To Reset
LedgetechCheckToReset:
    lwz r3, 0x4(r31)                                    # get timer #Get Timer
    cmpwi r3, 0x0                                       # Check if >0
    ble LedgetechThinkExit
    # Dec Timer
    subi r3, r3, 0x1
    stw r3, 0x4(r31)                                    # store timer
    cmpwi r3, 0x0                                       # Check if 0 now
    bne LedgetechThinkExit                              # Exit If Not

LedgetechRestoreState:
    # Restore State
    addi r3, EventData, EventData_SaveStateStruct
    bl SaveState_Load
    # Random Side of Stage
    li r3, 2
    branchl r12, HSD_Randi
    bl Ledgetech_InitializePositions
    # Enter SquatWait
    mr r3, P2GObj
    branchl r12, AS_SquatWait

    # Set Timer
    li r3, 0
    stw r3, 0x4(r31)
    # Reset Rebirth Plat Fall Flag
    stb r3, 0x8(r31)
    # Reset Tech and Gatekeeper Flag
    stb r3, 0x9(r31)
    stb r3, 0xA(r31)
    # Reset Score
    li r3, 0
    sth r3, -0x4ea8(r13)
    b LedgetechThinkExit

LedgetechThinkExit:
    restore
    blr

#################################

Ledgetech_Floats:
    blrl
    .float 35.0                                         # Distance to Initiate DSmash

#################################

BlrFunctionPointer:
    blrl
    blr

#################################

Ledgetech_InitializePositions:
    backup

    .set LedgeSide, 20

    # Backup Ledge Side
    mr LedgeSide, r3

    # Change Facing Directions
    cmpwi LedgeSide, 0x0
    beq Ledgetech_InitializePositions_GetLeftLedgeID

Ledgetech_InitializePositions_GetRightLedgeID:
    # Change Facing Direction
    li r3, -1
    bl IntToFloat
    stfs f1, 0x2C(P1Data)
    li r3, 1
    bl IntToFloat
    stfs f1, 0x2C(P2Data)
    b Ledgetech_InitializePositions_DirectionChangeEnd

Ledgetech_InitializePositions_GetLeftLedgeID:
    # Change Facing Direction
    li r3, 1
    bl IntToFloat
    stfs f1, 0x2C(P1Data)
    li r3, -1
    bl IntToFloat
    stfs f1, 0x2C(P2Data)

Ledgetech_InitializePositions_DirectionChangeEnd:
    # Get Ledge Coordinates
    mr r3, LedgeSide
    addi r4, sp, 0x80
    bl GetLedgeCoordinates

Ledgetech_InitializePositions_StorePosition:
    # Place P2 a few Mm behind it
    li r3, 10
    bl IntToFloat
    lfs f2, 0x2C(P2Data)
    fmuls f1, f1, f2
    lfs f2, 0x80(sp)
    fsubs f1, f2, f1
    stfs f1, 0xB0(P2Data)
    lfs f1, 0x84(sp)
    stfs f1, 0xB4(P2Data)
    # Find Ground Below Player
    mr r3, P2GObj
    bl FindGroundNearPlayer
    cmpwi r3, 0                                         # Check if ground was found
    beq Ledgetech_InitializePositions_SkipGroundCorrection
    stfs f1, 0xB0(P2Data)
    stfs f2, 0xB4(P2Data)
    stw r4, 0x83C(P2Data)

Ledgetech_InitializePositions_SkipGroundCorrection:
    # Enter into Wait
    mr r3, P2GObj
    branchl r12, AS_Wait
    # Update Position
    mr r3, P2GObj
    bl UpdatePosition
    # Update ECB Values for the ground ID
    mr r3, P2GObj
    branchl r12, EnvironmentCollision_WaitLanding
    # Set Grounded
    mr r3, P2Data
    branchl r12, Air_SetAsGrounded
    # Update Camera
    mr r3, P2GObj
    bl UpdateCameraBox

    # Enter Rebirth
    lwz r26, 0x2C(P1Data)
    mr r3, P1GObj
    branchl r12, AS_Rebirth
    stw r26, 0x2C(P1Data)
    # Place P1 a few Mm in front of it
    li r3, 60
    bl IntToFloat
    lfs f2, 0x2C(P1Data)
    fmuls f1, f1, f2
    lfs f2, 0x80(sp)
    fsubs f1, f2, f1
    stfs f1, 0xB0(P1Data)
    lfs f1, 0x84(sp)
    stfs f1, 0xB4(P1Data)
    # Enter RebirthWait
    mr r3, P1GObj
    branchl r12, AS_RebirthWait
    # Update Position
    mr r3, P1GObj
    bl UpdatePosition
    # Store Blr as Physics
    bl BlrFunctionPointer
    mflr r3
    stw r3, 0x21A4(P1Data)
    # Store Custom RebirthWait Interrupt
    bl Custom_InterruptRebirthWait
    mflr r3
    stw r3, 0x219C(P1Data)
    # Update RebirthPlat Position
    mr r3, P1GObj
    branchl r12, RebirthPlatform_UpdatePosition
    # Update Camera
    mr r3, P1GObj
    bl UpdateCameraBox

    restore
    blr

#################################

LedgetechLoadExit:
    restore
    blr

###################################################
