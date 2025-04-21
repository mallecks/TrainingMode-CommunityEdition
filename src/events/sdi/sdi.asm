##############################
## SDI Training HIJACK INFO ##
##############################

SDITraining:
    # Store Stage, CPU, and FDD Toggles
    lwz r3, 0x0(r29)                                    # Send event struct
    mr r4, r26                                          # Send match struct
    li r5, Fox.Ext                                      # Use chosen CPU
    li r6, FinalDestination                             # Use SSS Stage
    load r7, EventOSD_SDI
    li r8, 1                                            # Use Sopo bool
    bl InitializeMatch

    # Make default color
    lwz r3, 0x0(r29)
    lwz r3, 0x18(r3)                                    # p2 pointer
    li r4, 0x0
    stb r4, 0x3(r3)                                     # Default color

# STORE THINK FUNCTION
SDITrainingStoreThink:
    bl SDITrainingLoad
    mflr r3
    stw r3, 0x44(r26)                                   # on match load

    b exit

########################
## SDI Training LOAD FUNCT ##
########################
SDITrainingLoad:
    blrl

    backup

    bl InitializeHighScore

    # Schedule Think
    bl SDITrainingThink
    mflr r3
    li r4, 3                                            # Priority (After Interrupt)
    li r5, 0                                            # No Option Menu
    bl CreateEventThinkFunction

    b SDITrainingLoadExit

#########################
## SDI Training THINK FUNCT ##
#########################

    .set EventData, 31
    .set P1Data, 27
    .set P1GObj, 28
    .set P2Data, 29
    .set P2GObj, 30

SDITrainingThink:
    blrl
    backup

    # INIT FUNCTION VARIABLES
    lwz EventData, 0x2c(r3)                             # backup data pointer in r31

    bl GetAllPlayerPointers
    mr P1GObj, r3
    mr P1Data, r4
    mr P2GObj, r5
    mr P2Data, r6

    li r3, 0xF
    stw r3, 0x1A94(r29)
    bl StoreCPUTypeAndZeroInputs

    # ON FIRST FRAME
    bl CheckIfFirstFrame
    cmpwi r3, 0x0
    beq SDITrainingThinkMain

    bl SDITrainingFloats
    mflr r3
    bl Event_EnterGrab
    # Store 999 To Breakout
    lis r3, 0x4461
    stw r3, 0x1A4C(r27)
    # Give Percent
    bl SDITrainingStartingPercents
    mflr r4
    lwz r3, 0x4(r27)                                    # Get Char ID
    lbzx r3, r3, r4                                     # Get Percent
    load r4, 0x80453080                                 # P1 Static Block
    sth r3, 0x60(r4)                                    # Store Percent Int To Display Value
    sth r3, 0x62(r4)                                    # Store Percent Int To Display Value (Subchar)
    bl IntToFloat
    stfs f1, 0x1830(r27)                                # Store to Actual Damage Value
    # Clear Inputs
    bl RemoveFirstFrameInputs
    # Save State
    addi r3, EventData, EventData_SaveStateStruct
    li r4, 1                                            # Override failsafe code
    bl SaveState_Save
    # Random Start Time
    li r3, 60
    branchl r12, HSD_Randi
    li r4, 0
    sub r3, r4, r3
    stw r3, 0x4(r31)                                    # Reset Timer

SDITrainingThinkMain:
    # Inc Timer
    lwz r3, 0x4(r31)
    addi r3, r3, 0x1
    stw r3, 0x4(r31)

    # Check If SDI'd UpAir (Damage_LightHit + No Hitstun)
    # Check If Already Incremented
    lbz r3, 0xA(r31)
    cmpwi r3, 0x1
    beq SDITraining_SkipSDICheck
    # Check AS
    lwz r3, 0x10(r27)
    cmpwi r3, 0x55
    bne SDITraining_SkipSDICheck
    # Check For Hitstun
    lbz r3, 0x221C(r27)
    rlwinm. r0, r3, 31, 31, 31
    bne SDITraining_SkipSDICheck
    # Set Flag
    li r3, 0x1
    stb r3, 0xA(r31)
    # Play Sound
    li r3, 0xAD
    bl PlaySFX
    # Increment Score
    lhz r3, -0x4ea8(r13)
    addi r3, r3, 0x1
    sth r3, -0x4ea8(r13)
    # Check To Make New High Score
    lhz r3, -0x4ea8(r13)
    lhz r4, -0x4ea6(r13)
    cmpw r3, r4
    ble SDITraining_SkipSDICheck
    # Copy To High Score
    sth r3, -0x4ea6(r13)

SDITraining_SkipSDICheck:
    # Check If Missed SDI (Fox in UpAir + P1 in Damage Heavy State)
    # Check If Fox Is Up-Airing
    lwz r3, 0x10(r29)
    cmpwi r3, 0x44
    bne SDITraining_SkipMissedSDICheck
    # Check If P1 is in Hitlag
    lbz r3, 0x221A(r27)                                 # Check If in Hitlag
    rlwinm. r3, r3, 0, 26, 26
    beq SDITraining_SkipMissedSDICheck
    # Check If Fox is Past Frame 11
    li r3, 11
    bl IntToFloat
    lfs f2, 0x894(r29)
    fcmpo cr0, f2, f1
    blt SDITraining_SkipMissedSDICheck
    # Reset Score
    li r3, 0
    sth r3, -0x4ea8(r13)

SDITraining_SkipMissedSDICheck:
    # Update Score
    lhz r3, -0x4ea8(r13)
    branchl r12, HUD_KOCounter_UpdateKOs

    # Check State
    lbz r3, 0x8(r31)
    cmpwi r3, 0
    beq SDITrainingUpThrowThink
    cmpwi r3, 1
    beq SDITrainingFollowOpponentThink
    cmpwi r3, 2
    beq SDITrainingJumpThink
    cmpwi r3, 3
    beq SDITrainingUpAirThink
    cmpwi r3, 4
    beq SDITrainingCheckForReset

# ******************************************************#

SDITrainingUpThrowThink:
    # Check Timer
    lwz r3, 0x4(r31)
    cmpwi r3, 0x0
    blt SDITrainingThinkExit
    # Check If In Wait
    lwz r3, 0x10(r29)
    cmpwi r3, 0xE
    bne SDITrainingUpThrowThink_InputUpThrow

    # Advance to Next State
    li r3, 0x1
    stb r3, 0x8(r31)
    b SDITrainingFollowOpponentThink

SDITrainingUpThrowThink_InputUpThrow:
    # UpThrow
    li r3, 127
    stb r3, 0x1A8D(r29)
    b SDITrainingThinkExit

# ******************************************************#

SDITrainingFollowOpponentThink:
SDITrainingFollowOpponentThink_CheckIfAirbourne:
    lwz r3, 0xE0(r29)
    cmpwi r3, 0x1
    bne SDITrainingFollowOpponentThink_CheckDistance
    li r3, 0x2
    stb r3, 0x8(r31)
    b SDITrainingJumpThink

SDITrainingFollowOpponentThink_CheckDistance:
    # Determine Which Distance Value
    lwz r3, 0x10(r29)
    cmpwi r3, 0x14
    bne 0xC
    li r3, 15
    b 0x8
    li r3, 10
    bl SDITrainingInputTowardsOpponent
    # Check If Already Jumping, If So Follow Through
    lwz r4, 0x10(r29)
    cmpwi r4, 0x18
    beq SDITrainingFollowOpponentThink_CheckIfJumping
    cmpwi r3, 0x1                                       # Checks If In Range of Opponent
    bne SDITrainingThinkExit

# Check If Jumping
SDITrainingFollowOpponentThink_CheckIfJumping:
    lwz r3, 0x10(r29)
    cmpwi r3, 0x18
    bne SDITrainingFollowOpponentThink_InputJump
    # If Less than 32 Mm Away, Short Hop
    lfs f1, 0xB4(r27)                                   # P1 X Coord
    lfs f2, 0xB4(r29)                                   # P2 X Coord
    fsubs f3, f2, f1                                    # Get Difference
    li r3, 32
    bl IntToFloat
    fabs f2, f3
    fcmpo cr0, f2, f1
    blt SDITrainingThinkExit

# Input Jump
SDITrainingFollowOpponentThink_InputJump:
    li r3, 0x800
    stw r3, 0x1A88(r29)
    b SDITrainingThinkExit

# ******************************************************#

SDITrainingJumpThink:
    # Follow Opponent
    li r3, 5
    bl SDITrainingInputTowardsOpponent
    # When Less Than 35 Mm Away in the Y Direction, Up Air
    lfs f1, 0xB4(r27)                                   # P1 X Coord
    lfs f2, 0xB4(r29)                                   # P2 X Coord
    fsubs f3, f2, f1                                    # Get Difference
    li r3, 35
    bl IntToFloat
    fabs f2, f3
    fcmpo cr0, f2, f1
    bgt SDITrainingJumpThink_CheckToDJ
    # Input UpAir
    li r3, 127
    stb r3, 0x1A8F(r29)
    # Set Timer To Reset
    li r3, 60
    stb r3, 0x9(r31)
    # Advance State
    li r3, 0x3
    stb r3, 0x8(r31)
    b SDITrainingUpAirThink

SDITrainingJumpThink_CheckToDJ:
    # If in Frame X Of Jump, DJ
    lwz r3, 0x10(r29)
    cmpwi r3, 0x19
    beq SDITrainingJumpThink_CheckToDJ_InJump
    cmpwi r3, 0x1A
    beq SDITrainingJumpThink_CheckToDJ_InJump
    b SDITrainingThinkExit

SDITrainingJumpThink_CheckToDJ_InJump:
    li r3, 4
    bl IntToFloat
    lfs f2, 0x894(r29)
    fcmpo cr0, f1, f2
    bne SDITrainingThinkExit
    # Enter DJ
    li r3, 0x800
    stw r3, 0x1A88(r29)
    b SDITrainingThinkExit

# ******************************************************#

SDITrainingUpAirThink:
    # Check If UpAir Hitboxes Are Over
    li r3, 12
    bl IntToFloat
    lfs f2, 0x894(r29)
    fcmpo cr0, f2, f1
    bge SDITrainingCheckForReset
    # Follow Opponent
    li r3, 5
    bl SDITrainingInputTowardsOpponent
    # Check If Back On Ground
    lwz r3, 0xE0(r29)
    cmpwi r3, 0x0
    bne SDITrainingCheckForReset
    # Advance State
    li r3, 0x4
    stb r3, 0x8(r31)
    b SDITrainingCheckForReset

# ******************************************************#

SDITrainingInputTowardsOpponent:
# Returns a bool indicating if the character is within range

    backup

    mr r31, r3                                          # Backup Distance Threshold

    # Get X Distance
    lfs f1, 0xB0(r27)                                   # P1 X Coord
    lfs f2, 0xB0(r29)                                   # P2 X Coord
    fsubs f3, f2, f1                                    # Get Difference
    # If Within 4 Mm, Jump
    mr r3, r31
    bl IntToFloat
    fabs f2, f3
    fcmpo cr0, f2, f1
    bgt SDITrainingFollowOpponentThink_InputTowardsOpponent
    li r3, 0x1
    b SDITrainingInputTowardsOpponent_Exit

SDITrainingFollowOpponentThink_InputTowardsOpponent:
    # Push Towards Opponent's Direction
    bl GetDirectionInRelationToP1
    mulli r3, r3, -1                                    # Negate This
    li r4, 127
    mullw r3, r3, r4
    stb r3, 0x1A8C(r29)
    li r3, 0x0

SDITrainingInputTowardsOpponent_Exit:
    restore
    blr

# ******************************************************#

SDITrainingCheckForReset:
    lbz r3, 0x9(r31)
    cmpwi r3, 0x0
    beq SDITrainingThinkExit
    subi r3, r3, 0x1
    stb r3, 0x9(r31)
    cmpwi r3, 0x0
    bne SDITrainingThinkExit
    # Load State
    addi r3, EventData, EventData_SaveStateStruct
    bl SaveState_Load
    addi r3, EventData, EventData_SaveStateStruct
    bl SaveState_Load
    # Random Timer
    li r3, 60
    branchl r12, HSD_Randi
    mulli r3, r3, -1
    stw r3, 0x4(r31)
    # Reset State
    li r3, 0
    stb r3, 0x8(r31)
    # Reset SDI'd Flag
    li r3, 0x0
    stb r3, 0xA(r31)

SDITrainingThinkExit:
    restore
    blr

##############

Event_EnterGrab:
    backup

    mr r20, r3

    # Move P1
    lfs f1, 0x0(r20)
    stfs f1, 0xB0(r27)
    lfs f1, 0x4(r20)
    stfs f1, 0xB4(r27)
    mr r3, r28
    bl UpdatePosition
    mr r3, r28
    bl CheckIfPlayerHasAFollower
    cmpwi r3, 0
    beq Event_EnterGrab_MoveP2
    # Move Subchar
    lfs f1, 0x0(r20)
    stfs f1, 0xB0(r5)
    lfs f1, 0x4(r20)
    stfs f1, 0xB4(r5)
    bl UpdatePosition

Event_EnterGrab_MoveP2:
    # Move P2
    lfs f1, 0x8(r20)
    stfs f1, 0xB0(r29)
    lfs f1, 0xC(r20)
    stfs f1, 0xB4(r29)
    mr r3, r30
    bl UpdatePosition
    mr r3, r30
    bl CheckIfPlayerHasAFollower
    cmpwi r3, 0
    beq Event_EnterGrab_EnterGrabAS
    # Move Subchar
    lfs f1, 0x8(r20)
    stfs f1, 0xB0(r5)
    lfs f1, 0xC(r20)
    stfs f1, 0xB4(r5)
    bl UpdatePosition

Event_EnterGrab_EnterGrabAS:
    # Store P1 into P2 Grab Pointer
    stw r28, 0x1A58(r29)

    # Enter P2 Into Grab
    mr r3, r30                                          # P2 Enters Grab
    branchl r12, AS_GrabOpponent

    # Enter P1 Into Grabbed
    mr r3, r28                                          # P1 Grabbed
    mr r4, r30                                          # P2 = Grabber
    branchl r12, AS_Grabbed

    # Enter P2 Into GrabWait
    mr r3, r30                                          # P2 Enters GrabWait
    branchl r12, AS_CatchWait

    # Enter P2 Into Grounded
    mr r3, r29
    branchl r12, SetAsGrounded

    # Remove P2's GFX Pointer That Is Crashing the Game
    li r3, 0x0
    stw r3, 0x60C(r29)

    restore
    blr

##############

SDITrainingStartingPercents:
    blrl
    .long 0x085F8040                                    # Mario = 8 / Fox = 95 / Falcon = 70 / DK = 25
    .long 0x0030190F                                    # Kirby = 0 / Bowser = 25 / Link = 25 / Sheik = 15
    .long 0x00000000                                    # Ness = 0 / Peach = 0 / Popo = 0 / Nana = 0
    .long 0x08050F00                                    # Pikachu = 8 / Samus = 5 / Yoshi = 15 / Jiggs = 0
    .long 0x00001800                                    # Mewtwo = 0 / Luigi = 0 / Marth = 20 / Zelda = 0
    .long 0x19085F00                                    # YLink = 25 / Doc = 8 / Falco = 95 / Pichu = 0
    .long 0x002D3A00                                    # GaW = 0 / Ganon = 45 / Roy = 58

SDITrainingFloats:
    blrl
    .long 0xC02CCCCD                                    # P1 X Position
    .long 0x00000000                                    # P1 Y Position
    .long 0x4144CCCD                                    # P2 X Position
    .long 0x00000000                                    # P2 Y Position

SDITrainingLoadExit:
    restore
    blr

################################################################################
################################################################################
