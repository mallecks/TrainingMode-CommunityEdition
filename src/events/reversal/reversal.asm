#########################
## Reversal HIJACK INFO ##
#########################

Reversal:
    # Store Stage, CPU, and FDD Toggles
    lwz r3, 0x0(r29)                                    # Send event struct
    mr r4, r26                                          # Send match struct
    li r5, -1                                           # Use chosen CPU
    li r6, -1                                           # Use SSS Stage
    load r7, EventOSD_Reversal
    li r8, 0                                            # Use Sopo bool
    bl InitializeMatch

    # STORE THINK FUNCTION
    bl ReversalLoad
    mflr r3
    stw r3, 0x44(r26)                                   # on match load

    b exit

########################
## Reversal LOAD FUNCT ##
########################
ReversalLoad:
    blrl

    backup

    # Schedule Think
    bl ReversalThink
    mflr r3
    li r4, 3                                            # Priority (After Interrupt)
    bl ReversalWindowInfo
    mflr r5
    bl ReversalWindowText
    mflr r6
    bl CreateEventThinkFunction

    b ReversalLoadExit

#########################
## Reversal THINK FUNCT ##
#########################

    .set MenuData, 26
    .set EventData, 31
    .set P1Data, 27
    .set P1GObj, 28
    .set P2Data, 29
    .set P2GObj, 30

    .set firstFrameFlag, 0x0
    .set timer, 0x4
    .set CPUAttack, (MenuData_OptionMenuMemory+0x2)+(0x0)
    .set P1FacingDirection, (MenuData_OptionMenuMemory+0x2)+(0x1)
    .set CPUFacingDirection, (MenuData_OptionMenuMemory+0x2)+(0x2)
    .set Position, (MenuData_OptionMenuMemory+0x2)+(0x3)
    .set CPUAttackToggled, MenuData_OptionMenuToggled+(0x0)
    .set P1FacingDirectionToggled, MenuData_OptionMenuToggled+(0x1)
    .set CPUFacingDirectionToggled, MenuData_OptionMenuToggled+(0x2)
    .set PositionToggled, MenuData_OptionMenuToggled+(0x3)
    .set AerialThinkStruct, 0x20

ReversalThink:
    blrl

    .set EventData, 31

    backup

    # INIT FUNCTION VARIABLES
    lwz EventData, 0x2c(r3)                             # backup data pointer in r31
    lwz MenuData, EventData_MenuDataPointer(EventData)

    bl GetAllPlayerPointers
    mr P1GObj, r3
    mr P1Data, r4
    mr P2GObj, r5
    mr P2Data, r6

    li r3, 0xF
    stb r3, 0x1A94(r29)
    bl StoreCPUTypeAndZeroInputs

    # ON FIRST FRAME
    bl CheckIfFirstFrame
    cmpwi r3, 0x0
    beq ReversalThinkMain

    bl StageGetGroundID_Main
    bl PlacePlayersCenterStage
    # Clear Inputs
    bl RemoveFirstFrameInputs
    # SaveState
    addi r3, EventData, 0x10                            # SaveState start
    li r4, 1                                            # Override failsafe code
    bl SaveState_Save
    # Set Frame 1 As Over
    li r3, 0x1
    stb r3, 0x0(r31)
    # Set Timer to -60
    li r3, -60
    stw r3, 0x4(r31)

ReversalThinkMain:
    bl GiveFullShields

    # Reset when menu is toggled
    lbz r3, P1FacingDirectionToggled(MenuData)
    cmpwi r3, 0x0
    bne ReversalReset                                   # Only Run When Hovered Over Facing Direction
    lbz r3, CPUFacingDirectionToggled(MenuData)
    cmpwi r3, 0x0
    bne ReversalReset                                   # Only Run When Hovered Over Facing Direction
    lbz r3, CPUAttackToggled(MenuData)
    cmpwi r3, 0x0
    bne ReversalReset
    lbz r3, PositionToggled(MenuData)
    cmpwi r3, 0x0
    bne ReversalRemakeSavestate

ReversalSkipFacingReset:
    # Move Players Apart With DPad
    addi r3, EventData, 0x10                            # SaveState start
    bl AdjustResetDistance
    cmpwi r3, -1
    bne ReversalReset

ReversalThinkSequence:
    # Increment Timer
    lwz r20, 0x4(r31)                                   # get timer
    addi r20, r20, 0x1
    stw r20, 0x4(r31)                                   # store timer

    # Give Invincibility in Wait, Squat Reverse, IASA Flag Flipped
    lwz r3, 0x10(r29)
    cmpwi r3, 0xE
    beq ReversalGiveInvincibility
    cmpwi r3, 0x29
    beq ReversalGiveInvincibility
    lbz r3, 0x2218(r29)
    rlwinm. r3, r3, 25, 31, 31
    bne ReversalGiveInvincibility
    b ReversalCheckToAttack

ReversalGiveInvincibility:
    mr r3, r30
    li r4, 0x2
    bl GiveInvincibility

# Check To Attack
ReversalCheckToAttack:
    # Check Timer
    cmpwi r20, 45
    blt ReversalThinkExit
    # Check If Attack is Over
    lbz r3, AerialThinkStruct(r31)
    cmpwi r3, 0x0
    bne ReversalCheckToReset

ReversalDecideSmashAttack:
    lbz r3, CPUAttack(MenuData)
    cmpwi r3, 0x0
    beq ReversalRandomSmashAttack
    cmpwi r3, 0x1
    beq ReversalFSmash
    cmpwi r3, 0x2
    beq ReversalDSmash
    cmpwi r3, 0x3
    beq ReversalUSmash
    cmpwi r3, 0x4
    beq ReversalRandomAerial
    cmpwi r3, 0x5
    beq ReversalNair
    cmpwi r3, 0x6
    beq ReversalFair
    cmpwi r3, 0x7
    beq ReversalDair
    cmpwi r3, 0x8
    beq ReversalFTilt
    cmpwi r3, 0x9
    beq ReversalDTilt
    cmpwi r3, 0xA
    beq ReversalUTilt
    cmpwi r3, 0xB
    beq ReversalGetupAttackStomach
    cmpwi r3, 0xC
    beq ReversalGetupAttackBack

ReversalRandomSmashAttack:
    li r3, 3
    branchl r12, HSD_Randi
    mr r21, r3
    # Check If Move is Blacklisted
    lwz r4, 0x4(r29)                                    # Char ID
    bl Reversal_Blacklist
    mflr r5                                             # Get Frame Data Table
    mulli r4, r4, 0x4                                   # Get Characters Offset
    add r4, r4, r5                                      # Get Characters Table Entry Start
    lbzx r4, r21, r4                                    # Get Moves Entry
    cmpwi r4, 0x1                                       # Is Move BlackListed?
    beq ReversalRandomSmashAttack

    # Perform Move
    cmpwi r21, 0x0
    beq ReversalFSmash
    cmpwi r21, 0x1
    beq ReversalUSmash
    cmpwi r21, 0x2
    beq ReversalDSmash

ReversalFSmash:
    # Input Atack
    li r3, 127                                          # Forward
    lfs f1, 0x2C(r29)                                   # Facing Direction
    fctiwz f1, f1
    stfd f1, 0xF0(sp)
    lwz r4, 0xF4(sp)
    mullw r3, r3, r4                                    # Forward * facing direction
    stb r3, 0x1A8E(r29)
    # Set Attack as ended
    li r3, 0x1
    stb r3, AerialThinkStruct(r31)
    b ReversalCheckToReset

ReversalUSmash:
    li r3, 127
    stb r3, 0x1A8F(r29)
    b ReversalCheckToReset
    # Set Attack as ended
    li r3, 0x1
    stb r3, AerialThinkStruct(r31)

ReversalDSmash:
    li r3, -127
    stb r3, 0x1A8F(r29)
    # Set Attack as ended
    li r3, 0x1
    stb r3, AerialThinkStruct(r31)
    b ReversalCheckToReset

ReversalRandomAerial:
    # Perform Aerial
    mr r3, r30
    addi r4, r31, AerialThinkStruct
    li r5, 0                                            # Random Aerial
    bl PerformAerialThink
    b ReversalCheckToReset

ReversalNair:

ReversalFair:

ReversalDair:
    # Perform Aerial
    subi r5, r3, 0x4
    mr r3, r30
    addi r4, r31, AerialThinkStruct
    bl PerformAerialThink
    b ReversalCheckToReset

ReversalFTilt:
    li r3, 45
    lfs f1, 0x2C(r29)                                   # Facing Direction
    fctiwz f1, f1
    stfd f1, 0xF0(sp)
    lwz r4, 0xF4(sp)
    mullw r3, r3, r4                                    # Forward * facing direction
    stb r3, 0x1A8C(r29)
    li r3, 0x100
    stw r3, 0x1A88(r29)
    # Set Attack as ended
    li r3, 0x1
    stb r3, AerialThinkStruct(r31)
    b ReversalCheckToReset

ReversalUTilt:
    li r3, 45
    stb r3, 0x1A8D(r29)
    li r3, 0x100
    stw r3, 0x1A88(r29)
    # Set Attack as ended
    li r3, 0x1
    stb r3, AerialThinkStruct(r31)
    b ReversalCheckToReset

ReversalDTilt:
    li r3, -45
    stb r3, 0x1A8D(r29)
    li r3, 0x100
    stw r3, 0x1A88(r29)
    # Set Attack as ended
    li r3, 0x1
    stb r3, AerialThinkStruct(r31)
    b ReversalCheckToReset

ReversalGetupAttackStomach:
    li r3, 0x100
    stw r3, 0x1A88(r29)
    li r3, 0x1
    stb r3, AerialThinkStruct(r31)
    b ReversalCheckToReset

ReversalGetupAttackBack:
    # Hack: set state id as DownBoundU to force back getup attack
    li r3, 183
    stw r3, 0x10(P2Data)

    mr r3, P2GObj
    branchl r12, 0x80097e8c
    li r3, 0x100
    stw r3, 0x1A88(r29)
    li r3, 0x1
    stb r3, AerialThinkStruct(r31)
    b ReversalCheckToReset

ReversalCheckToReset:
    cmpwi r20, 150                                      # Restore After 120 Frames
    blt ReversalThinkExit
    b ReversalReset

ReversalRemakeSavestate:
    lbz r3, Position(MenuData)
    cmpwi r3, 0
    beq ReversalRemakeSavestate_MainStage

    bl StageGetGroundID_Platform
    cmpwi r3, 0x0FFF
    blt ReversalRemakeSavestate_PlaceCharacters

ReversalRemakeSavestate_MainStage:
    bl StageGetGroundID_Main

ReversalRemakeSavestate_PlaceCharacters:
    bl PlacePlayersCenterStage
    # Clear Inputs
    bl RemoveFirstFrameInputs
    # SaveState
    addi r3, EventData, 0x10                            # SaveState start
    li r4, 1                                            # Override failsafe code
    bl SaveState_Save
    # Set Frame 1 As Over
    li r3, 0x1
    stb r3, 0x0(r31)
    # Set Timer to -60
    li r3, -60
    stw r3, 0x4(r31)

ReversalReset:

ReversalSwap:
    # I fucking hate this code, i need to clean this up at some point.
    # Get leftmost player pointer in r20, rightmost in r21
    addi r5, EventData, 0x10
    lwz r3, 0x0(r5)
    lfs f1, 0xB0(r3)
    lwz r4, 0x8(r5)
    lfs f2, 0xB0(r4)
    fcmpo cr0, f1, f2
    bgt 0x10
    mr r20, r3
    mr r21, r4
    b 0xC
    mr r20, r4
    mr r21, r3
    # Get which side to start on
    li r3, 2                                            # 0 = p1 on left, 1 = p1 on right
    branchl r12, HSD_Randi
    cmpwi r3, 0x0
    bne ReversalReset_RightSide

ReversalReset_LeftSide:
    # Swap Position
    addi r5, EventData, 0x10
    # Get Leftmost Chars Position
    li r3, 1
    bl IntToFloat
    fmr f2, f1
    lfs f3, 0xB0(r20)
    lfs f4, 0xB4(r20)
    # Get Rightmost Chars Position
    li r3, -1
    bl IntToFloat
    fmr f5, f1
    lfs f6, 0xB0(r21)
    lfs f7, 0xB4(r21)
    # Store to P1 Data
    lwz r3, 0x0(r5)
    stfs f2, 0x2C(r3)
    stfs f3, 0xB0(r3)
    stfs f4, 0xB4(r3)
    # Store to P2 Data
    lwz r3, 0x8(r5)
    stfs f5, 0x2C(r3)
    stfs f6, 0xB0(r3)
    stfs f7, 0xB4(r3)
    b ReversalReset_SwapEnd

ReversalReset_RightSide:
    addi r5, EventData, 0x10
    # Get Leftmost Chars Position
    li r3, 1
    bl IntToFloat
    fmr f2, f1
    lfs f3, 0xB0(r20)
    lfs f4, 0xB4(r20)
    # Get Rightmost Chars Position
    li r3, -1
    bl IntToFloat
    fmr f5, f1
    lfs f6, 0xB0(r21)
    lfs f7, 0xB4(r21)
    # Store to P2 Data
    lwz r3, 0x8(r5)
    stfs f2, 0x2C(r3)
    stfs f3, 0xB0(r3)
    stfs f4, 0xB4(r3)
    # Store to P1 Data
    lwz r3, 0x0(r5)
    stfs f5, 0x2C(r3)
    stfs f6, 0xB0(r3)
    stfs f7, 0xB4(r3)

ReversalReset_SwapEnd:

ReversalAdjustP1Direction:
    # Adjust P1 Facing Direction Based on Preference
    addi r5, EventData, 0x10
    lbz r3, P1FacingDirection(MenuData)
    cmpwi r3, 0x1
    bne ReversalAdjustP1Direction_Skip
    # Invert P1 Facing Direction
    lwz r3, 0x0(r5)
    lfs f1, 0x2C(r3)
    fneg f1, f1
    stfs f1, 0x2C(r3)

ReversalAdjustP1Direction_Skip:

# Adjust CPU Facing Direction Based on Preference
ReversalAdjustCPUDirection:
    lbz r3, CPUFacingDirection(MenuData)
    cmpwi r3, 0x1
    bne ReversalAdjustCPUDirection_Skip
    # Invert P2 Facing Direction
    lwz r3, 0x8(r5)
    lfs f1, 0x2C(r3)
    fneg f1, f1
    stfs f1, 0x2C(r3)

ReversalAdjustCPUDirection_Skip:

# Restore
ReversalLoadState:
    addi r3, EventData, EventData_SaveStateStruct
    bl SaveState_Load
    # Reset Timer
    li r3, 30
    branchl r12, HSD_Randi
    li r4, 0
    sub r3, r4, r3
    stw r3, 0x4(r31)
    # Reset AerialThinkStruct
    li r3, 0x0
    stw r3, AerialThinkStruct(r31)

Reversal_CheckEnterDownWait:
    lbz r3, CPUAttack(MenuData)
    cmpwi r3, 0xB
    beq Reversal_EnterDownBoundD
    cmpwi r3, 0xC
    beq Reversal_EnterDownBoundU
    b ReversalThinkExit

Reversal_EnterDownBoundU:
    # Hack: set state id as DownBoundU to force back getup attack
    li r3, 183
    stw r3, 0x10(P2Data)

Reversal_EnterDownBoundD:
    mr r3, P2GObj
    branchl r12, 0x80097e8c

ReversalThinkExit:
    mr r3, MenuData
    bl ClearToggledOptions
    bl UpdateAllGFX
    restore
    blr

#################################

Reversal_Floats:
    blrl
    .long 0xC0F9999A                                    # P1 X Position
    .long 0x40F9999A                                    # P2 X Position
    .float 50.0
    .float 50.0
    #.long 0x38d1b717                                    # FD Floor Y Coord
    #.long 0x38d1b717                                    # FD Floor Y Coord

#################################

Reversal_Blacklist:
    blrl
    # Mario
    .long 0x00000000                                    # FSmash USmash DSmash

    # Fox
    .long 0x01000000                                    # FSmash USmash DSmash

    # Cptn Falcon
    .long 0x00000000                                    # FSmash USmash DSmash

    # DK
    .long 0x00010000                                    # FSmash USmash DSmash

    # Kirby
    .long 0x00000000                                    # FSmash USmash DSmash

    # Bowser
    .long 0x00010000                                    # FSmash USmash DSmash

    # link
    .long 0x00000000                                    # FSmash USmash DSmash

    # Sheik
    .long 0x01000000                                    # FSmash USmash DSmash

    # Ness
    .long 0x00010100                                    # FSmash USmash DSmash

    # Peach
    .long 0x00010000                                    # FSmash USmash DSmash

    # Popo
    .long 0x00000000                                    # FSmash USmash DSmash

    # Nana
    .long 0x00000000                                    # FSmash USmash DSmash

    # Pikachu
    .long 0x00000000                                    # FSmash USmash DSmash

    # Samus
    .long 0x00010000                                    # FSmash USmash DSmash

    # Yoshi
    .long 0x00010000                                    # FSmash USmash DSmash

    # Jiggs
    .long 0x00010000                                    # FSmash USmash DSmash

    # mewtwo
    .long 0x00010000                                    # FSmash USmash DSmash

    # Luigi
    .long 0x00000000                                    # FSmash USmash DSmash

    # Marth
    .long 0x00010000                                    # FSmash USmash DSmash

    # Zelda
    .long 0x00010000                                    # FSmash USmash DSmash

    # YLink
    .long 0x00000000                                    # FSmash USmash DSmash

    # Doc
    .long 0x00000000                                    # FSmash USmash DSmash

    # Falco
    .long 0x01000000                                    # FSmash USmash DSmash

    # Pichu
    .long 0x00000000                                    # FSmash USmash DSmash

    # GaW
    .long 0x00000100                                    # FSmash USmash DSmash

    # Ganon
    .long 0x00000000                                    # FSmash USmash DSmash

    # Roy
    .long 0x00010000                                    # FSmash USmash DSmash

####################################################

ReversalWindowInfo:
    blrl
# amount of options, amount of options in each window

    .long 0x030C0101                                    # 3 window, Smash Attack has 13 options, Facing Direction Has 2
    .long 0x01000000                                    # Position has 2

####################################################

ReversalWindowText:
    blrl

########
## DI ##
########

    # Window Title = CPU Attack
    .long 0x43505520
    .long 0x41747461
    .long 0x636b0000

    # Option 1 = Random Smash Attack
    .long 0x52616e64
    .long 0x6f6d2053
    .long 0x6d617368
    .long 0x20417474
    .long 0x61636b00

    # Option 2 = Forward Smash
    .long 0x466f7277
    .long 0x61726420
    .long 0x536d6173
    .long 0x68000000

    # Option 3 = Down Smash
    .long 0x446f776e
    .long 0x20536d61
    .long 0x73680000

    # Option 4 = Up Smash
    .long 0x55702053
    .long 0x6d617368
    .long 0x00000000

    # Option 5 = Random Aerial
    .long 0x52616e64
    .long 0x6f6d2041
    .long 0x65726961
    .long 0x6c000000

    # Option 6 = Fair
    .long 0x46616972
    .long 0x00000000

    # Option 7 = Nair
    .long 0x4e616972
    .long 0x00000000

    # Option 8 = Dair
    .long 0x44616972
    .long 0x00000000

    # Option 9 = FTilt
    .long 0x4654696c
    .long 0x74000000

    # Option 10 = DTilt
    .long 0x4454696c
    .long 0x74000000

    # Option 11 = UTilt
    .long 0x5554696c
    .long 0x74000000

    # Option 12 - Getup Attack (Stomach)
    .string "Getup Attack (Stomach)"

    # Option 13 - Getup Attack (Back)
    .string "Getup Attack (Back)"

#########$$$#############
## P1 Facing Direction ##
##########$$$############

    # Window Title = Facing Direction
    .long 0x50312046
    .long 0x6163696e
    .long 0x67204469
    .long 0x72656374
    .long 0x696f6e00

    # Option 1 = Towards
    .long 0x546f7761
    .long 0x72647300
    .long 0x00000000
    .long 0x00000000
    .long 0x00000000

    # Option 2 = Away
    .long 0x41776179
    .long 0x00000000
    .long 0x00000000
    .long 0x00000000
    .long 0x00000000

#########$$$##############
## CPU Facing Direction ##
##########$$$#############

    # Window Title = CP Facing Direction
    .long 0x43502046
    .long 0x6163696e
    .long 0x67204469
    .long 0x72656374
    .long 0x696f6e00

    # Option 1 = Towards
    .long 0x546f7761
    .long 0x72647300
    .long 0x00000000
    .long 0x00000000
    .long 0x00000000

    # Option 2 = Away
    .long 0x41776179
    .long 0x00000000
    .long 0x00000000
    .long 0x00000000
    .long 0x00000000

##############
## Position ##
##############

    # Window Title
    .string "Position"

    # Options
    .string "Ground"
    .string "Platform"


    .align 2
####################################################

ReversalLoadExit:
    restore
    blr

################################################################################
################################################################################
