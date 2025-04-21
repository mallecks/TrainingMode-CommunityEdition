#########################
## Multishine HIJACK INFO ##
#########################

Multishine:
    # COUNT DOWN TIME
    li r3, 0x6
    stb r3, 0x0(r26)

    # 10 Seconds On the Clock
    li r3, 10
    stw r3, 0x10(r26)

    # Store Match Type to READY, GO!
    li r3, 0x80
    stb r3, 0x1(r26)

    # SET EVENT TYPE TO KOs
    load r5, 0x8045abf0                                 # Static Match Struct
    lbz r3, 0xB(r5)                                     # Get Event Score Behavior Byte
    li r4, 0x0
    rlwimi r3, r4, 1, 30, 30                            # Zero Out Time Bit
    stb r3, 0xB(r5)                                     # Set Event Score Behavior Byte

    # Store Stage, CPU, and FDD Toggles
    lwz r3, 0x0(r29)                                    # Send event struct
    mr r4, r26                                          # Send match struct
    li r5, -1                                           # Use chosen CPU
    li r6, FinalDestination                             # Use FD
    load r7, EventOSD_Multishine
    li r8, 0                                            # Use Sopo Bool
    bl InitializeMatch

    # 1 Player
    lwz r4, 0x0(r29)
    li r3, 0x20
    stb r3, 0x1(r9)

    # STORE THINK FUNCTION
    bl MultishineLoad
    mflr r3
    stw r3, 0x44(r26)                                   # on match load

    b exit

########################
## Multishine LOAD FUNCT ##
########################
MultishineLoad:
    blrl

    backup

    # Schedule Think
    bl MultishineThink
    mflr r3
    li r4, 17                                           # Priority (After Everything)
    li r5, 0                                            # No Option Menu
    li r6, 0
    bl CreateEventThinkFunction

    bl InitializeHighScore

    b MultishineLoadExit

#########################
## Multishine THINK FUNCT ##
#########################

MultishineThink:
    blrl

    .set EventData, 31
    .set Event, 30
    .set P1Data, 27
    .set P1GObj, 28

    backup

    mr Event, r3
    lwz EventData, 0x2c(Event)

    bl GetAllPlayerPointers
    mr P1GObj, r3
    mr P1Data, r4

    # First Frame Actions
    bl CheckIfFirstFrame
    cmpwi r3, 0x0
    beq MultishineNotFirstFrame
    # Init Positions
    bl StageGetGroundID_Main
    bl PlacePlayersCenterStage

MultishineNotFirstFrame:
    # Check for grounded or aerial shine, frame 1
    lwz r3, 0x10(P1Data)
    cmpwi r3, 0x168
    beq Multishine_IsShining
    cmpwi r3, 0x16D
    beq Multishine_IsShining
    b Multishine_SkipShineCheck

Multishine_IsShining:
    # Check for frame 1
    lhz r3, TM_FramesinCurrentAS(P1Data)
    cmpwi r3, 0
    bne Multishine_SkipShineCheck
    # Increment Score
    li r3, 0
    li r4, 0
    li r5, 5
    branchl r12, Playerblock_StoreTimesR3KilledR4

Multishine_SkipShineCheck:
    # Check For TimeUp
    branchl r12, MatchInfo_LoadSeconds                  # Seconds Left
    cmpwi r3, 0x0
    bne MultishineThinkExit
    branchl r12, MatchInfo_LoadSubSeconds               # Sub-Seconds Left
    cmpwi r3, 59
    bne MultishineThinkExit
    # On Event End
    mr r3, Event
    branchl r12, EventMatch_OnWinCondition              # EventMatch_OnWinCondition

MultishineThinkExit:
    # Update HUD Score
    li r3, 0
    li r4, 5
    branchl r12, Playerblock_LoadTimesR3KilledR4
    branchl r12, HUD_KOCounter_UpdateKOs

MultishineLoadExit:
    restore
    blr

################################################################################
################################################################################
