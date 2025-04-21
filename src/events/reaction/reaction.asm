#########################
## Reaction HIJACK INFO ##
#########################

Reaction:
    # SET EVENT TYPE TO KOs
    load r5, 0x8045abf0                                 # Static Match Struct
    lbz r3, 0xB(r5)                                     # Get Event Score Behavior Byte
    li r4, 0x0
    rlwimi r3, r4, 1, 30, 30                            # Zero Out Time Bit
    stb r3, 0xB(r5)                                     # Set Event Score Behavior Byte

    # Store Stage, CPU, and FDD Toggles
    lwz r3, 0x0(r29)                                    # Send event struct
    mr r4, r26                                          # Send match struct
    li r5, Fox.Ext                                      # Use chosen CPU
    li r6, FinalDestination                             # Use FD
    load r7, EventOSD_Reaction
    li r8, 0                                            # Use Sopo Bool
    bl InitializeMatch

    # STORE THINK FUNCTION
    bl ReactionLoad
    mflr r3
    stw r3, 0x44(r26)                                   # on match load

    b exit

########################
## Reaction LOAD FUNCT ##
########################
ReactionLoad:
    blrl

    backup

    # Schedule Think
    bl ReactionThink
    mflr r3
    li r4, 3                                            # Priority (Interrupt)
    li r5, 0                                            # No Option Menu
    li r6, 0
    bl CreateEventThinkFunction

    b ReactionLoadExit

#########################
## Reaction THINK FUNCT ##
#########################

ReactionThink:
    blrl

    .set EventData, 31
    .set Event, 30
    .set P1Data, 27
    .set P1GObj, 28
    .set P2Data, 29
    .set P2GObj, 30

    # Constants
    .set ShineTimerMax, 7*60
    .set ShineTimerMin, 3*60
    .set ResetTimer, 1*60

    # GObj Data Offsets
    .set OFST_ShineTimer, 0x0
    .set OFST_ResetTimer, 0x2
    .set OFST_ReactionTimer, 0x4

    backup

    mr Event, r3
    lwz EventData, 0x2c(Event)

    bl GetAllPlayerPointers
    mr P1GObj, r3
    mr P1Data, r4
    mr P2GObj, r5
    mr P2Data, r6

    # First Frame Actions
    bl CheckIfFirstFrame
    cmpwi r3, 0x0
    beq ReactionNotFirstFrame
    # Init Positions
    bl StageGetGroundID_Main
    bl PlacePlayersCenterStage
    # Savestate
    addi r3, EventData, EventData_SaveStateStruct
    li r4, 1
    bl SaveState_Save
    # Set Initial Timer
    li r3, ShineTimerMax - ShineTimerMin
    branchl r12, HSD_Randi
    addi r3, r3, ShineTimerMin
    sth r3, OFST_ShineTimer(EventData)
    # Initialize Reaction Timer
    li r3, -1
    sth r3, OFST_ReactionTimer(EventData)
    # Stop Music
    li r3, 0
    li r4, 2
    branchl r12, 0x80025064

ReactionNotFirstFrame:
    bl StoreCPUTypeAndZeroInputs

    # Give Intangibility to both chars
    mr r3, P1GObj
    li r4, 1
    branchl r12, ApplyIntangibility
    mr r3, P2GObj
    li r4, 1
    branchl r12, ApplyIntangibility

    # Check post countdown timer
    lhz r3, OFST_ResetTimer(EventData)
    cmpwi r3, 0
    ble Reaction_SkipResetTimer
    # Dec timer, if 0 reset
    subi r3, r3, 1
    sth r3, OFST_ResetTimer(EventData)
    cmpwi r3, 0
    beq Reaction_Reset
    b ReactionThinkExit

Reaction_SkipResetTimer:
    # Check shine countdown timer
    lhz r3, OFST_ShineTimer(EventData)
    cmpwi r3, 0
    ble Reaction_SkipShineTimer
    # Dec timer, if 0 perform move
    subi r3, r3, 1
    sth r3, OFST_ShineTimer(EventData)
    cmpwi r3, 0
    bgt ReactionThink_CheckIfActedEarly
    # Perform down b
    mr r3, P2GObj
    branchl r12, 0x800e8560
    # Start reaction timer
    li r3, 0
    sth r3, OFST_ReactionTimer(EventData)
    b ReactionThinkExit

ReactionThink_CheckIfActedEarly:
    # Check if P1 acted early
    lwz r3, 0x10(P1Data)
    cmpwi r3, ASID_Wait
    beq ReactionThinkExit
    # Play Error Noise
    li r3, 0xAF
    bl PlaySFX
    # Set Timer
    li r3, ResetTimer-40
    sth r3, OFST_ResetTimer(EventData)
    b ReactionThinkExit

Reaction_SkipShineTimer:
    # Check reaction timer
    lhz r3, OFST_ReactionTimer(EventData)
    extsh r3, r3
    cmpwi r3, 0
    blt Reaction_SkipReactionTimer
    # Poll Inputs Again
    # branchl r12, 0x80377ce8
    # Check if P1 Reacted
    lbz r3, 0x618(P1Data)
    load r4, InputStructStart
    mulli r3, r3, 68
    add r3, r3, r4
    lwz r3, 0x8(r3)
    cmpwi r3, 0
    beq Reaction_SkipReactionTimer
    # Output reaction time
    mr r3, P1Data                                       # p1(no offsetting window)
    li r4, 120                                          # text timeout
    li r5, 0                                            # Area to Display (0-2)
    li r6, OSD.Miscellaneous                            # Window ID(Unique to This Display)
    branchl r12, TextCreateFunction                     # create text custom function
    mr r20, r3                                          # backup text pointer
    # Decide Color
    lhz r3, OFST_ReactionTimer(EventData)
    cmpwi r3, 15
    ble Reaction_Good

Reaction_Bad:
    load r3, 0xffa2baff                                 # Red
    b Reaction_StoreTextColor

Reaction_Good:
    load r3, 0x8dff6eff                                 # green

Reaction_StoreTextColor:
    stw r3, 0x30(r20)

    # Create Text 1
    mr r3, r20                                          # text pointer
    bl Reaction_TopText
    mflr r4
    lfs f1, -0x37B4(rtoc)                               # default text X/Y
    lfs f2, -0x37B4(rtoc)                               # default text X/Y
    branchl r12, Text_InitializeSubtext

    # Create Text 2
    mr r3, r20                                          # text pointer
    bl Reaction_BottomText
    mflr r4
    lhz r5, OFST_ReactionTimer(EventData)
    addi r5, r5, 1                                      # 0-index is scary
    lfs f1, -0x37B4(rtoc)                               # default text X/Y
    lfs f2, -0x37B0(rtoc)                               # default text X/Y
    branchl r12, Text_InitializeSubtext

    # Start post countdown timer
    li r3, ResetTimer
    sth r3, OFST_ResetTimer(EventData)
    b ReactionLoadExit

Reaction_SkipReactionTimer:
    # Inc timer
    lhz r3, OFST_ReactionTimer(EventData)
    addi r3, r3, 1
    sth r3, OFST_ReactionTimer(EventData)
    b ReactionThinkExit

Reaction_Reset:
    # Load State
    addi r3, EventData, EventData_SaveStateStruct
    bl SaveState_Load
    # Reset Variables
    # Set Initial Timer
    li r3, ShineTimerMax - ShineTimerMin
    branchl r12, HSD_Randi
    addi r3, r3, ShineTimerMin
    sth r3, OFST_ShineTimer(EventData)
    # Reset Timer
    li r3, 0
    sth r3, OFST_ResetTimer(EventData)
    # Initialize Reaction Timer
    li r3, -1
    sth r3, OFST_ReactionTimer(EventData)

ReactionThinkExit:

ReactionLoadExit:
    restore
    blr

Reaction_TopText:
    blrl
    .string "Reaction Time:"
    .align 2

Reaction_BottomText:
    blrl
    .string "%d Frames"
    .align 2

################################################################################
################################################################################
