#########################
## Amsah Tech HIJACK INFO ##
#########################

AmsahTech:
    # Store Stage, CPU, and FDD Toggles
    lwz r3, 0x0(r29)                                    # Send event struct
    mr r4, r26                                          # Send match struct
    li r5, 9                                            # Use chosen CPU
    li r6, -1                                           # Use chosen Stage
    load r7, EventOSD_AmsahTech
    li r8, 1                                            # Use Sopo bool
    bl InitializeMatch

    # STORE THINK FUNCTION
    bl AmsahTechLoad
    mflr r3
    stw r3, 0x44(r26)                                   # on match load

    b exit

########################
## Amsah Tech LOAD FUNCT ##
########################
AmsahTechLoad:
    blrl

    backup

    # Schedule Think
    bl AmsahTechThink
    mflr r3
    li r4, 3                                            # Priority (After Interrupt)
    bl AmsahTechWindowInfo
    mflr r5
    bl AmsahTechWindowText
    mflr r6
    bl CreateEventThinkFunction

    b AmsahTechLoadExit

#########################
## Amsah Tech THINK FUNCT ##
#########################

    .set EventData, 31
    .set P1Gobj, 28
    .set P1Data, 27
    .set P2GObj, 30
    .set P2Data, 29

    # Offsets
    .set Timer, 0x8
    .set UpBTimerOption, MenuData_OptionMenuMemory+0x2 + 0x0
    .set ResetTimerOption, MenuData_OptionMenuMemory+0x2 + 0x1
    .set UpBTimerOptionToggled, MenuData_OptionMenuToggled + 0x0
    .set ResetTimerOptionToggled, MenuData_OptionMenuToggled + 0x1

AmsahTechThink:
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
    beq AmsahTechThinkMain

    # Move Players
    bl StageGetGroundID_Main
    bl PlacePlayersCenterStage
    # P1 Has 120%
    li r3, 120
    load r4, 0x80453080                                 # P1 Static Block
    sth r3, 0x60(r4)                                    # Store Percent Int To Display Value
    bl IntToFloat
    stfs f1, 0x1830(P1Data)
    # Clear Inputs
    bl RemoveFirstFrameInputs
    # Save State
    addi r3, EventData, EventData_SaveStateStruct
    li r4, 1                                            # Override failsafe code
    bl SaveState_Save

AmsahTechThinkMain:
    # Make P2 A Follower (No Nudge)
    # li r3, 0x8
    # stb r3, 0x221F(r29)
    li r3, 0x1
    lbz r0, 0x221D(r29)
    rlwimi r0, r3, 2, 29, 29
    stb r0, 0x221D(r29)

    # Give Invincibility To P2
    mr r3, r30
    li r4, 0x2
    bl GiveInvincibility

    # Update GFX
    mr r3, r30
    bl UpdateAllGFX

    # Reset If Anyone Dies
    bl IsAnyoneDead
    cmpwi r3, 0x0
    bne AmsahTechRestoreState

AmsahTechThinkSequence:
    # Get Floats
    bl AmsahTech_Floats
    mflr r21

    # Check If Timer Started Already
    lwz r3, 0x4(r31)
    cmpwi r3, 0x0
    bne AmsahTechCheckUpBTimer

    # Check For P1 Taunt
    lwz r3, 0x10(r27)
    cmpwi r3, 0x108
    beq AmsahTechIsTaunting
    cmpwi r3, 0x109
    beq AmsahTechIsTaunting

    # Check For Doc Taunt
    lwz r3, 0x4(r27)
    cmpwi r3, 0x15
    bne AmsahTechCheckYLink
    # Check For AS 155
    lwz r3, 0x10(r27)
    cmpwi r3, 0x155
    beq AmsahTechIsTaunting

# Check For YLink Taunt
AmsahTechCheckYLink:
    lwz r3, 0x4(r27)
    cmpwi r3, 0x14
    bne AmsahTechCheckUpBTimer
    # Check For AS 156
    lwz r3, 0x10(r27)
    cmpwi r3, 0x156
    beq AmsahTechIsTaunting
    b AmsahTechCheckUpBTimer

AmsahTechIsTaunting:
    # Check for Frame 1 of Taunt
    lhz r3, TM_FramesinCurrentAS(P1Data)
    cmpwi r3, 0x1
    bne AmsahTechCheckUpBTimer
    # Check If UpB Timer is Set
    lwz r3, 0x8(r31)
    cmpwi r3, 0x0                                       # Timer Already Set
    bne AmsahTechCheckUpBTimer
    # Check If Marth is In Wait
    lwz r3, 0x10(r29)
    cmpwi r3, 0xE
    bne AmsahTechCheckUpBTimer

    # Move Marth X Mm in front of P1, facing him
    # Get Position
    li r3, 10
    bl IntToFloat                                       # Offset from P1
    lfs f3, 0xB0(P1Data)                                # P1 X
    lfs f2, 0xB4(P1Data)                                # P1 Y
    lfs f4, 0x2C(P1Data)                                # Facing Direction
    fmuls f1, f1, f4
    fadds f1, f1, f3
    # Check If P2 Will Be Grounded
    li r3, 0
    bl FindGroundNearPlayer
    cmpwi r3, 0                                         # Check if ground was found
    beq AmsahTech_NoGroundFound
    stfs f1, 0xB0(P2Data)
    stfs f2, 0xB4(P2Data)
    stw r4, 0x83C(P2Data)
    lfs f1, 0x2C(P1Data)
    fneg f1, f1
    stfs f1, 0x2C(P2Data)
    # Enter Wait
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

AmsahTechSetUpBTimer:
    lbz r3, UpBTimerOption(MenuData)
    cmpwi r3, 0x0
    beq AmsahTechSetUpBTimer_30
    cmpwi r3, 0x1
    beq AmsahTechSetUpBTimer_50

AmsahTechSetUpBTimer_30:
    li r3, 30
    stw r3, Timer(EventData)
    b AmsahTechStoreToBackupsAsWell

AmsahTechSetUpBTimer_50:
    li r3, 50
    stw r3, Timer(EventData)
    b AmsahTechStoreToBackupsAsWell

AmsahTechStoreToBackupsAsWell:
    lwz r3, 0x18(EventData)                             # P2 Backup
    lfs f1, 0xB0(P2Data)                                # Get P2 X
    stfs f1, 0xB0(r3)                                   # Store to P2 Backup
    lfs f1, 0xB4(P2Data)                                # Get P2 Y
    stfs f1, 0xB4(r3)                                   # Store to P2 Backup
    lfs f1, 0x2C(P2Data)                                # Get P2 Facing
    stfs f1, 0x2C(r3)                                   # Store to P2 Backup
    lwz r4, 0x83C(P2Data)                               # Get P2 Ground ID
    stw r4, 0x83C(r3)                                   # Store to P2 Backup
    lwz r3, 0x10(EventData)                             # P1 Backup
    lfs f1, 0xB0(P1Data)                                # Get P1 X
    stfs f1, 0xB0(r3)                                   # Store to P1 Backup
    lfs f1, 0xB4(P1Data)                                # Get P1 X
    stfs f1, 0xB4(r3)                                   # Store to P1 Backup
    lfs f1, 0x2C(P1Data)                                # Get P1 Facing
    stfs f1, 0x2C(r3)                                   # Store to P1 Backup
    lwz r4, 0x83C(P1Data)                               # Get P1 Ground ID
    stw r4, 0x83C(r3)                                   # Store to P1 Backup
    mr r3, P1GObj
    bl CheckIfPlayerHasAFollower
    cmpwi r3, 0x0
    beq AmsahTechNoSubchar
    lwz r3, 0x14(EventData)                             # P1 Subchar Backup
    lfs f1, 0xB0(r4)                                    # Get P1 Subchar X
    stfs f1, 0xB0(r3)                                   # Store to P1 Subchar Backup
    lfs f1, 0x2C(r4)                                    # Get P1 Subchar Facing
    stfs f1, 0x2C(r3)                                   # Store to P1 Subchar Backup

AmsahTechNoSubchar:
    b AmsahTechCheckToReset

AmsahTech_NoGroundFound:
    # Play Error SFX
    li r3, 0xAF
    bl PlaySFX
    b AmsahTechCheckToReset

AmsahTechCheckUpBTimer:
    # Check For UpBTimer
    lwz r3, 0x8(r31)
    cmpwi r3, 0x0                                       # No UpB Timer Set Yet
    ble AmsahTechCheckToReset
    # Dec Timer
    subi r3, r3, 0x1
    stw r3, 0x8(r31)                                    # store timer
    cmpwi r3, 0x0                                       # Check if 0 now
    bne AmsahTechCheckToReset                           # Exit If Not
    # Move Marth in Front of P1 Again (Fox's
    lfs f1, 0xB0(r27)                                   # Get P1 X
    lfs f2, 0x2C(r27)                                   # Get P1 Facing
    lfs f3, 0x10(r21)                                   # Get Marth Distance
    fmuls f2, f2, f3                                    # Distance * Facing Direction
    fadds f1, f1, f2                                    # P1.X + (Distance * Facing Direction)
    stfs f1, 0xB0(r29)                                  # Store Position to P2
    # Enter UpB
    li r3, 0x200
    stw r3, 0x1A88(r29)
    li r3, 127
    stb r3, 0x1A8D(r29)

AmsahTechInitiateResetTimer:
    lbz r3, ResetTimerOption(MenuData)
    cmpwi r3, 0x0
    beq AmsahTechResetTimer_120
    cmpwi r3, 0x1
    beq AmsahTechResetTimer_180
    cmpwi r3, 0x2
    beq AmsahTechResetTimer_240

AmsahTechResetTimer_120:
    li r3, 120
    stw r3, 0x4(r31)
    b AmsahTechCheckToReset

AmsahTechResetTimer_180:
    li r3, 180
    stw r3, 0x4(r31)
    b AmsahTechCheckToReset

AmsahTechResetTimer_240:
    li r3, 240
    stw r3, 0x4(r31)
    b AmsahTechCheckToReset

AmsahTechCheckToReset:
    lwz r3, 0x4(r31)                                    # get timer #Get Timer
    cmpwi r3, 0x0                                       # No Reset Timer Set Yet
    ble AmsahTechThinkExit
    # Dec Timer
    subi r3, r3, 0x1
    stw r3, 0x4(r31)                                    # store timer
    cmpwi r3, 0x0                                       # Check if 0 now
    bne AmsahTechThinkExit                              # Exit If Not

AmsahTechRestoreState:
    # Restore State
    addi r3, EventData, EventData_SaveStateStruct
    bl SaveState_Load
    # Restore Timers Just In Case
    li r3, 0x0
    stw r3, 0x4(r31)
    stw r3, 0x8(r31)

AmsahTechThinkExit:
    restore
    blr

#################################

AmsahTech_Floats:
    blrl
    .long 0x4308ca0c                                    # P1 X Position
    .long 0x42942371                                    # P2 X Position
    .long 0x00000000                                    # P1 Y Position
    .long 0x38d1b717                                    # FD Floor Y Coord
    .long 0x41800000                                    # Distance to place Marth from P1
    .long 0x428C0000                                    # FD Stage Boundary X


#################################

AmsahTechWindowInfo:
    blrl
    # amount of options, amount of options in each window
    .long 0x01010200                                    # 2 window, Up B Timer has 2 options, Reset Timer has 3 options

####################################################

AmsahTechWindowText:
    blrl

#############################
## Up B Timer Frame Option ##
#############################

    # Window Title
    .string "Up B Timer Frame"
    .align 2

    # Option 1
    .string "30"
    .align 2

    # Option 2
    .string "50"
    .align 2

#############################
## Reset Timer Frame Option ##
#############################

    # Window Title
    .string "Reset Timer Frame"
    .align 2

    # Option 1
    .string "120"
    .align 2

    # Option 2
    .string "180"
    .align 2

    # Option 3
    .string "240"
    .align 2

AmsahTechLoadExit:
    restore
    blr

###########################################
