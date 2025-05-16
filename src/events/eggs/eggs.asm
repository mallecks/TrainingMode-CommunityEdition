#########################
## Eggs-ercise HIJACK INFO ##
#########################

Eggs:
    # COUNT DOWN TIME
    li r3, 0x6
    stb r3, 0x0(r26)

    # 1 Minute On the Clock
    li r3, 60
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

    # 1 Player
    lwz r4, 0x0(r29)
    li r3, 0x20
    stb r3, 0x1(r4)

    # STORE THINK FUNCTION
    bl EggsLoad
    mflr r3
    stw r3, 0x44(r26)                                   # on match load

    b exit

########################
## Eggs-ercise LOAD FUNCT ##
########################
EggsLoad:
    blrl

    backup

    # Schedule Think
    # r3 = function to run each frame
    # r4 = priority
    # r5 = pointer to Window and Option Count
    # r6 = pointer to ASCII struct
    bl EggsThink
    mflr r3
    li r4, 9                                            # Priority (After Interrupt)
    bl EggsWindowInfo
    mflr r5
    bl EggsWindowText
    mflr r6
    bl CreateEventThinkFunction

    bl InitializeHighScore

    b EggsLoadExit

#########################
## Eggs-ercise THINK FUNCT ##
#########################

    # Registers
    .set EventData, 31
    .set MenuData, 26
    .set P1Data, 27
    .set P1GObj, 28

    # Offsets
    .set DamageThreshold, (MenuData_OptionMenuMemory+0x2) +0x0
    .set DamageThresholdToggled, (MenuData_OptionMenuToggled) +0x0

EggsThink:
    blrl
    backup

    # Get and Backup Event Data
    mr r30, r3                                          # r30 = think entity
    lwz EventData, 0x2c(r3)                             # backup data pointer in r31
    lwz MenuData, EventData_MenuDataPointer(EventData)

    # Get Player Data
    bl GetAllPlayerPointers
    mr P1GObj, r3
    mr P1Data, r4

    # No Staling
    bl ResetStaleMoves

    # Check If Free Practice
    lbz r3, 0x5(r31)
    cmpwi r3, 0x0
    bne EggsSkipFreePracticeCheck
    # Check DPad Down
    lwz r0, 0x668(r27)
    rlwinm. r0, r0, 0, 29, 29
    beq EggsSkipFreePracticeCheck
    # Toggle Free Practice On
    li r3, 0x1
    stb r3, 0x5(r31)
    # Timer Now Counts Up
    load r3, 0x8046b6a0
    lbz r0, 0x24C8(r3)
    li r4, 1
    rlwimi r0, r4, 0, 31, 31
    stb r0, 0x24C8(r3)
    # Play Sound To Indicate
    li r3, 0x82
    branchl r12, SFX_PlaySoundAtFullVolume

EggsSkipFreePracticeCheck:
    # Check If Toggled
    lbz r3, DamageThresholdToggled(MenuData)
    cmpwi r3, 0x0
    beq EggsSkipToggleCheck
    # Check If Already Free Practice
    lbz r3, 0x5(r31)
    cmpwi r3, 0x0
    bne EggsSkipToggleCheck
    # Make Free Practice
    li r3, 0x1
    stb r3, 0x5(r31)
    # Timer Now Counts Up
    load r3, 0x8046b6a0
    lbz r0, 0x24C8(r3)
    li r4, 1
    rlwimi r0, r4, 0, 31, 31
    stb r0, 0x24C8(r3)
    # Play Sound To Indicate
    li r3, 0x82
    branchl r12, SFX_PlaySoundAtFullVolume

EggsSkipToggleCheck:
    # Check For First Frame
    lbz r3, 0x4(r31)
    cmpwi r3, 0x0
    bne EggsNotFirstFrame

    # Check If Player Can Move
    li r3, 0x0
    branchl r12, PlayerBlock_LoadMainCharDataOffset     # get player block
    lwz r3, 0x2c(r3)                                    # player data in r29

    lbz r3, 0x221D(r3)
    rlwinm. r3, r3, 0, 28, 28
    bne EggsThinkExit

    # Set First Frame Over
    li r3, 0x1
    stb r3, 0x4(r31)

EggsNotFirstFrame:
# Check If Target is Spawned
EggsTargetCheck:
    # Check If Pointer is Stored
    lwz r3, 0x0(r31)
    cmpwi r3, 0x0
    beq EggsThinkSpawn
    # Check if Item GObj is live
    lwz r3, 0x2C(r3)
    cmpwi r3, 0x0
    beq EggsThinkSpawn
    b EggsThinkSkipSpawn

################
# Spawn Target #
################

    .set LeftCameraBound, 20
    .set RightCameraBound, 21
    .set TopCameraBound, 22
    .set BottomCameraBound, 23

EggsThinkSpawn:
    .if debug==1
    li r24, 0                                           # Init loop count
    .endif

EggsThinkSpawnLoop:
    .if debug==1
    addi r24, r24, 1                                    # Inc Loop Count
    .endif

    # Get OnScreen Boundaries
    # Left Camera
    branchl r12, StageInfo_CameraLimitLeft_Load
    fctiwz f1, f1
    stfd f1, 0x80(sp)
    lwz LeftCameraBound, 0x84(sp)
    # Right Camera
    branchl r12, StageInfo_CameraLimitRight_Load
    fctiwz f1, f1
    stfd f1, 0x80(sp)
    lwz RightCameraBound, 0x84(sp)
    # Top Camera
    branchl r12, StageInfo_CameraLimitTop_Load
    fctiwz f1, f1
    stfd f1, 0x80(sp)
    lwz TopCameraBound, 0x84(sp)
    # Bottom Camera
    branchl r12, StageInfo_CameraLimitBottom_Load
    fctiwz f1, f1
    stfd f1, 0x80(sp)
    lwz BottomCameraBound, 0x84(sp)

    # Get Random Velocity
    branchl r12, HSD_Randf
    fmr f20, f1
    li r3, 2
    bl IntToFloat
    fadds f20, f20, f1

    # Get Random X Value Between These
    mr r3, LeftCameraBound
    mr r4, RightCameraBound
    bl RandFloat
    fmr f21, f1

    # Get Random Y Value Between These
    mr r3, BottomCameraBound
    subi r4, TopCameraBound, 70                         # Minus 40 so it doesnt fly up offscreen
    bl RandFloat
    fmr f22, f1

    .set EggSpawnGroundWidth, 8
    # Check If Egg is Above Ground
    fmr f1, f21
    fmr f2, f22
    bl FindGroundUnderCoordinate
    cmpwi r3, 0x0
    beq EggsThinkSpawnLoop
    # Check Left
    li r3, EggSpawnGroundWidth
    bl IntToFloat
    fsubs f1, f21, f1
    fmr f2, f22
    bl FindGroundUnderCoordinate
    cmpwi r3, 0x0
    beq EggsThinkSpawnLoop
    # Check Right
    li r3, EggSpawnGroundWidth
    bl IntToFloat
    fadds f1, f21, f1
    fmr f2, f22
    bl FindGroundUnderCoordinate
    cmpwi r3, 0x0
    beq EggsThinkSpawnLoop

    .if debug==1
    # OSReport Loop Count
    load r3, 0x803ead3c
    mr r4, r24
    branchl r12, OSReport
    .endif

SpawnEgg:
    addi r3, sp, 0x80
    li r4, 0x0
    stw r4, 0x0(r3)                                     # Player Pointer
    stw r4, 0x4(r3)                                     # Player Pointer
    li r4, 0x03
    stw r4, 0x8(r3)                                     # Item ID
    lfs f0, -0x2858(rtoc)
    stfs f21, 0x14(r3)                                  # X Coord
    stfs f22, 0x18(r3)                                  # Y Coord
    stfs f0, 0x1C(r3)                                   # Z Coord
    stfs f21, 0x20(r3)                                  # X Coord
    stfs f22, 0x24(r3)                                  # Y Coord
    stfs f0, 0x28(r3)                                   # Z Coord
    stfs f0, 0x2C(r3)                                   # Unk
    stfs f0, 0x30(r3)                                   # Unk
    stfs f0, 0x34(r3)                                   # X Vel
    stfs f0, 0x38(r3)                                   # Y Vel
    li r4, 0x1
    sth r4, 0x3C(r3)
    branchl r12, EntityItemSpawn
    mr r29, r3                                          # Backup Entity Pointer

    stw r29, 0x0(r31)                                   # Store Pointer To Target In Event Think

    # Store Pointer To Event Think In Target
    lwz r4, 0x2C(r29)
    stw r31, 0xDDC(r4)

    # Store Y Velocity
    stfs f20, 0x44(r4)

    # Get OnDestroy
    lwz r4, 0x2C(r29)
    lwz r4, 0xB8(r4)

    # Store OnCollision
    bl Eggs_OnCollision
    mflr r3
    stw r3, 0x1C(r4)

    # Create Camera Box
    branchl r12, CreateCameraBox
    # Attach to Entity
    lwz r4, 0x2c(r29)
    stw r3, 0x0520(r4)
    # Enable Camera Box Bit
    lbz r0, 0x0DCD(r4)
    li r5, 0x22
    rlwimi r0, r5, 5, 24, 25
    stb r0, 0x0DCD(r4)
    # Copy Some Stuff To Camera Box
    lwz r4, -0x4978(r13)
    lfs f0, 0x014C(r4)
    stfs f0, 0x0040(r3)
    lfs f0, 0x0150(r4)
    stfs f0, 0x0044(r3)
    lfs f0, 0x0154(r4)
    stfs f0, 0x0048(r3)
    lfs f0, 0x0158(r4)
    stfs f0, 0x004C(r3)

    # Never Timeout
    lwz r5, 0x002C(r29)
    lbz r3, 0xDD0(r5)
    li r4, 0x1
    rlwimi r3, r4, 4, 27, 27
    stb r3, 0xDD0(r5)

    # Not Grabbable
    lbz r3, 0x0DCA(r5)
    li r4, 0x0
    rlwimi r3, r4, 2, 29, 29
    stb r3, 0x0DCA(r5)

    # Un-Nudgeable?
    lbz r3, 0x0DCB(r5)
    li r4, 0x0
    rlwimi r3, r4, 3, 28, 28
    stb r3, 0x0DCB(r5)

EggsThinkSkipSpawn:
    # Not Grabbable Every Frame
    lwz r5, 0x0(r31)
    lwz r5, 0x2c(r5)
    lbz r3, 0x0DCA(r5)
    li r4, 0x0
    rlwimi r3, r4, 2, 29, 29
    stb r3, 0x0DCA(r5)

    # Update HUD Score
    li r3, 0
    li r4, 5
    branchl r12, Playerblock_LoadTimesR3KilledR4
    branchl r12, HUD_KOCounter_UpdateKOs

    # Check If Free Practice
    lbz r3, 0x5(r31)
    cmpwi r3, 0x0
    bne EggsThinkExit
    # Check For TimeUp
    branchl r12, MatchInfo_LoadSeconds                  # Seconds Left
    cmpwi r3, 0x0
    bne EggsThinkExit
    branchl r12, MatchInfo_LoadSubSeconds               # Sub-Seconds Left
    cmpwi r3, 59
    bne EggsThinkExit
    # On Event End
    mr r3, r30
    branchl r12, EventMatch_OnWinCondition              # EventMatch_OnWinCondition

EggsThinkExit:
    mr r3, MenuData
    bl ClearToggledOptions
    restore
    blr

Eggs_OnCollision:
    blrl

    # First check if this is an event
    load r4, SceneController
    lbz r4, Scene.CurrentMajor(r4)
    cmpwi r4, Scene.EventMode
    beq Eggs_OnCollisionStart

Eggs_OnCollisionOriginalFunction:
    # Go to the original egg break function
    branch r12, ItemCollision_Egg

Eggs_OnCollisionStart:
    backup
    mr r30, r3
    lwz r31, 0x2C(r3)                                   # Get Data

    # Check If Any Attack Should Break
    lwz r3, 0xDDC(r31)                                  # Get Event Data
    lwz r3, EventData_MenuDataPointer(r3)               # Get Menu Data
    lbz r3, DamageThreshold(r3)                         # Damage Behavior
    cmpwi r3, 0x1
    beq Eggs_OnCollisionBreakEgg
    # Check Damage Dealt Before Exploding
    lwz r3, 0xCA0(r31)
    cmpwi r3, 11
    blt Egg_OnCollisionExit

Eggs_OnCollisionBreakEgg:
    # Increment Score
    li r3, 0
    li r4, 0
    li r5, 5
    branchl r12, Playerblock_StoreTimesR3KilledR4

    # Display Effect
    li r3, 1232
    mr r4, r30
    addi r5, r31, 76
    crclr 6
    branchl r12, Textures_DisplayEffectTextures

    # Play Pop Sound
    mr r3, r31
    li r4, 244
    li r5, 127
    li r6, 64
    branchl r12, 0x8026ae84

    # Explode
    mr r3, r30
    branchl r12, 0x80289158

    # Spawn New Egg
    lwz r3, 0xDDC(r31)                                  # Get Event Think
    li r4, 0x0                                          # Get 0
    stw r4, 0x0(r3)                                     # Zero Pointer

Egg_OnCollisionExit:
    li r3, 0x0

Egg_OnCollisionExitSkip:
    restore
    blr

EggsLoadExit:
    restore
    blr

####################################################

EggsWindowInfo:
    blrl
# amount of options, amount of options in each window

    .long 0x0001FFFF                                    # 1 window, Smash Attack has 2 options

####################################################

EggsWindowText:
    blrl

######################
## Damage Threshold ##
######################

    # Window Title = Damage Threshold
    .long 0x44616d61
    .long 0x67652054
    .long 0x68726573
    .long 0x686f6c64
    .long 0x00000000

    # Option 1 = 12+ Damage
    .long 0x3132817B
    .long 0x2044616d
    .long 0x61676500
    .long 0x00000000
    .long 0x00000000

    # Option 2 = Any Damage
    .long 0x416e7920
    .long 0x44616d61
    .long 0x67650000
    .long 0x00000000
    .long 0x00000000

################################################################################
################################################################################
