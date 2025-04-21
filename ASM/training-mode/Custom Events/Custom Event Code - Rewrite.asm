    # To be inserted at 801bb128
    .include "../../Globals.s"
    .include "../../m-ex/Header.s"

    # Check if event is legacy (no file)
    lwz r3, MemcardData(r13)
    lbz r3, CurrentEventPage(r3)
    mr r4, r25                                          # event
    mr r5, r26                                          # match struct
    rtocbl r12, TM_GetEventFile
    cmpwi r3, 0
    beq LegacyEvent

    # Branch to C function to initialize the event
    lwz r3, MemcardData(r13)
    lbz r3, CurrentEventPage(r3)
    mr r4, r25                                          # event
    mr r5, r26                                          # match struct
    rtocbl r12, TM_EventInit
    branch r12, 0x801bb738

LegacyEvent:
# r25 = event ID
# r26 = final match struct
# r28 = same as r26
# r29 = event struct index (0x0 of this, then 0x8 of that to get the specifics)

    # Event GObj Data Struct
    .set EventData_DataSize, 0x50
    .set EventData_MenuDataPointer, (EventData_DataSize-0x4)
    .set EventData_SaveStateStruct, 0x10

    # Menu GObj Data Struct
    .set MenuData_DataSize, 0x50
    .set MenuData_EventDataPointer, (MenuData_DataSize-0x4)
    .set MenuData_WindowOptionCountPointer, 0x0
    .set MenuData_ASCIIStructPointer, 0x4
    .set MenuData_OptionMenuMemory, 0x8
    .set MenuData_OptionMenuToggled, 0x28

#################
## Custom Code ##
#################

# all registers free

    # 1 PLAYER, NO ITEMS, TIME COUNTING UP
    lwz r9, 0x0(r29)                                    # get event pointers

    # ZERO OUT p2-p6 STRUCT
    li r4, 0x0
    stw r4, 0x18(r9)
    stw r4, 0x1C(r9)
    stw r4, 0x20(r9)
    stw r4, 0x24(r9)
    stw r4, 0x28(r9)

    # Disable All-Star Flag
    li r3, 0x0
    stb r3, 0x0(r9)

    # P1 = Choose Char + Normal Modifiers
    bl P1Struct
    mflr r3
    stw r3, 0x14(r9)

    # STORE MATCH SETTINGS
    load r3, 0x0BB0027C                                 # HUD and timer behavior
    stw r3, 0x0(r26)
    load r3, 0x90800000
    stw r3, 0x4(r26)                                    # think functions
    li r3, 0xFF
    stb r3, 0xB(r26)                                    # items to none
    li r3, 0x0
    stw r3, 0x10(r26)                                   # time amount

    # STORE UNLIM STOCKS
    li r3, 0xFF
    stb r3, 0x62(r26)                                   # p1 stocks

    # SET FALL FLAG
    li r3, 0x0
    stb r3, 0x6C(r26)

    # SET FFA FLAG
    li r3, 0
    stb r3, 0x8(r26)

    # Store SSS Stage
    load r3, 0x80497758
    lha r4, 0x001E(r3)
    sth r4, 0xE(r26)

    # Get Event Code
    bl SkipPageList

    ##### Page List #######
    EventJumpTable

#######################
Minigames:
    bl Eggs
    bl Multishine
    bl Reaction
    bl LedgeStall
    .long -1

#######################
GeneralTech:
    bl 0x0              # Training
    bl 0x0              # LCancel
    bl 0x0              # Ledgedash
    bl 0x0              # Wavedash
    bl 0x0              # EmptyEvent
    bl ComboTraining
    bl AttackOnShield
    bl Reversal
    bl SDITraining
    bl Powershield
    bl Ledgetech
    bl AmsahTech
    bl ShieldDrop
    bl WaveshineSDI
    bl SlideOff
    bl GrabMashOut
    .long -1

#######################
SpacieTech:
    bl LedgetechCounter
    bl ArmadaShine
    bl SideBSweetspot
    bl EscapeSheik
    .long -1

#######################

SkipPageList:
    # Get Page Jump Table
    mflr r4                                             # Jump Table Start in r4
    # Get Current Page
    lwz r3, MemcardData(r13)
    lbz r3, CurrentEventPage(r3)
    mulli r5, r3, 0x4                                   # Each Pointer is 0x4 Long
    add r4, r4, r5                                      # Get Event's Pointer Address
    lwz r5, 0x0(r4)                                     # Get bl Instruction
    rlwinm r5, r5, 0, 6, 29                             # Mask Bits 6-29(the offset)
    add r4, r4, r5                                      # Gets ASCII Address in r4
    # Get Event Code Pointer
    mulli r5, r25, 0x4                                  # Each Pointer is 0x4 Long
    add r4, r4, r5                                      # Get Event's Pointer Address
    lwz r5, 0x0(r4)                                     # Get bl Instruction
    cmpwi r5, -1
    beq EventNoExist
    rlwinm r5, r5, 0, 6, 29                             # Mask Bits 6-29(the offset)
    add r4, r4, r5                                      # Gets ASCII Address in r4
    mtctr r4
    bctr

EventNoExist:
    b exit

###############
## Minigames ##
###############







##################
## General Tech ##
##################

LedgeCliffIDs:
    blrl
    .long 0xFFFFFFFF                                    # Dummy, TEST
    .long 0x03073336                                    # FoD, Pokemon Stadium
    .long 0x030D2945                                    # Peach's Castle, Kongo Jungle
    .long 0x0511091A                                    # Brinstar, Corneria
    .long 0x02061517                                    # Yoshi's Story, Onett
    .long 0x0000434C                                    # Mute City, Rainbow Cruise
    .long 0x00000000                                    # Jungle Japes, Great Bay
    .long 0x0E0D0000                                    # Hyrule Temple, Brinstar Depths
    .long 0x00051E2E                                    # Yoshi's Island, Green Greens
    .long 0x0C0E0204                                    # Fourside, MKI
    .long 0x03050000                                    # MKII, Akaneia
    .long 0x06120000                                    # Venom, PokeFloats
    .long 0xD7E20000                                    # Big Blue, Icicle Mountain
    .long 0x00000000                                    # Icetop, Flatzone
    .long 0x0305030B                                    # Dream Land, Yoshis Island 64
    .long 0x06100005                                    # Kongo Jungle 64, Battlefield
    .long 0x00020101                                    # Final Destination

.include "../../../build/generated_include_events.asm"

##############
## Fox Tech ##
##############






###############
## P1 STRUCT ##
###############
P1Struct:
    blrl

    .long 0x01000200                                    # external char, player type, stocks, costume
    .long 0xff000400                                    # spawn point, subcolor, team, voice pitch
    .long 0x00040700                                    # player flag
    .long 0x00000000                                    # level and starting %
    .long 0x3f800000                                    # attk ratio
    .long 0x3f800000                                    # def ratio
    .long 0x3f800000                                    # model scale

###############
## P2 STRUCT ##
###############
P2Struct:
    blrl

    .long 0x01010200                                    # external char, player type, stocks, costume
    .long 0xff000400                                    # spawn point, subcolor, team, voice pitch
    .long 0x00040700                                    # player flag
    .long 0x00000000                                    # level and starting %
    .long 0x3f800000                                    # attk ratio
    .long 0x3f800000                                    # def ratio
    .long 0x3f800000                                    # model scale

###########################
## Create Think Function ##
###########################
CreateEventThinkFunction:
    # Registers
    .set WindowOptionCount, 31
    .set ASCIIStruct, 30
    .set EventGObj, 29
    .set EventData, 28
    .set MenuGObj, 27
    .set MenuData, 26
    .set Priority, 25
    .set Function, 24

    backup

    mr Function, r3
    mr Priority, r4
    mr WindowOptionCount, r5
    mr ASCIIStruct, r6

########################
## Create Event Think ##
########################

    # Create GObj
    li r3, 6                                            # GObj Type
    li r4, 7                                            # On-Pause Function
    li r5, 80
    branchl r12, GObj_Create

    # Backup Allocation
    mr EventGObj, r3

    # Schedule Task
    mr r4, Function
    mr r5, Priority
    branchl r12, GObj_AddProc

    # Give Task Some Data Space
    li r3, EventData_DataSize                           # 50 bytes of space
    branchl r12, HSD_MemAlloc                           # HSD_MemAlloc
    mr EventData, r3

    # Initalize GObj
    mr r6, r3
    mr r3, EventGObj                                    # task space
    li r4, 0x0                                          # typedef
    load r5, HSD_Free                                   # destructor (HSD_Free)
    branchl r12, GObj_AddUserData                       # Create Data Block

    # Zero Dataspace
    mr r3, EventData
    li r4, EventData_DataSize
    branchl r12, ZeroAreaLength                         # zero length

##############################
## Create Option Menu Think ##
##############################

    # Check if Option Menu is enabled for this event
    cmpwi WindowOptionCount, 0
    beq CreateEventThinkFunction_NoOptionMenu

    # Create GObj
    li r3, 6                                            # GObj Type
    li r4, 0                                            # On-Pause Function
    li r5, 80
    branchl r12, GObj_Create

    # Backup Allocation
    mr MenuGObj, r3

    # Schedule Task
    bl OptionMenuThink
    mflr r4
    li r5, 22                                           # Last Function to Run
    branchl r12, GObj_AddProc

    # Give Task Some Data Space
    li r3, MenuData_DataSize                            # 50 bytes of space
    branchl r12, HSD_MemAlloc                           # HSD_MemAlloc
    mr MenuData, r3

    # Initalize GObj
    mr r6, MenuData
    mr r3, MenuGObj                                     # task space
    li r4, 0x0                                          # typedef
    load r5, HSD_Free                                   # destructor (HSD_Free)
    branchl r12, GObj_AddUserData                       # Create Data Block

    # Zero Dataspace
    mr r3, MenuData
    li r4, MenuData_DataSize
    branchl r12, ZeroAreaLength                         # zero length

    # Store Option Menu info to Dataspace
    stw WindowOptionCount, MenuData_WindowOptionCountPointer(MenuData)
    stw ASCIIStruct, MenuData_ASCIIStructPointer(MenuData)

    # Store Pointers to Each Other
    stw MenuData, EventData_MenuDataPointer(EventData)
    stw EventData, MenuData_EventDataPointer(MenuData)

CreateEventThinkFunction_NoOptionMenu:
    # Disable Hazards
    bl DisableHazards

CreateEventThinkFunction_Exit:
    restore
    blr

####################################
## Create Option Menu When Paused ##
####################################

OptionMenuThink:
    blrl

    .set MenuData, 31

    backup

    # Load Data Pointer
    lwz MenuData, 0x2C(r3)

    # Check If Paused
    li r3, 1
    branchl r12, DevelopMode_FrameAdvanceCheck
    cmpwi r3, 0x2
    bne OptionMenuThink_Exit

# Run OptionThink Code
OptionMenuThink_CheckInputs:
    addi r3, MenuData, MenuData_OptionMenuMemory
    lwz r4, MenuData_WindowOptionCountPointer(MenuData)
    lwz r5, MenuData_ASCIIStructPointer(MenuData)
    bl OptionWindow

    # Store Modified Option Bool
    cmpwi r3, 0
    beq OptionMenuThink_Exit
    addi r5, MenuData, MenuData_OptionMenuToggled
    stbx r3, r4, r5

OptionMenuThink_Exit:
    restore
    blr

##########################
## Clear Option Toggled ##
##########################

ClearToggledOptions:
# in
# r3 = Menu Data

    # Get Amount of Options
    lwz r4, MenuData_WindowOptionCountPointer(r3)
    lbz r4, 0x0(r4)

    # Loop Through All Data
    addi r3, r3, MenuData_OptionMenuToggled
    li r5, 0

ClearToggledOptions_Loop:
    stbx r5, r3, r4                                     # Zero Byte
    subi r4, r4, 1
    cmpwi r4, 0
    bge ClearToggledOptions_Loop

ClearToggledOptions_Exit:
    blr

######################
## Save States Main ##
######################

# 0x0 -> 0x23EC = player block
# 0x23EC -> 0x24EC = Static Block
# 0x24EC = Camera Flag

################################
## Save State Quick Functions ##
################################

SaveState_Save:
    .set REG_SaveStruct, 31
    .set REG_PlayerTotal, 30
    .set REG_LoopCount, 29
    .set REG_isSubchar, 23
    .set REG_Backup, 28
    .set REG_SpawnedOrder, 22
    .set REG_PlayerGObj, 25
    .set REG_PlayerData, 26
    .set REG_PlayerDataSize, 24
    .set REG_PlayerData_Backup, 27

    backup

    # Backup Task Data
    mr REG_SaveStruct, r3
    # Backup "skip failsafe" bool
    mr r20, r4

    # Count Players in Match
    branchl r3, 0x8016b558

    # Move Player Number to REG_PlayerTotal
    mr REG_PlayerTotal, r3

    # Check to run failsafe code
    cmpwi r20, 0x0
    bne SaveState_SaveLoopInit

SaveState_OnDeathCheck:
    # Mini loop to make sure no players have on-death functions
    li REG_LoopCount, 0x0                               # player ID
    li REG_isSubchar, 0x0                               # main/sub char bool

SaveState_OnDeathCheckLoop:
    # Get Proper Player Data
    mr r3, REG_LoopCount
    mr r4, REG_isSubchar
    bl SaveState_GetPlayerDataPointer                   # returns player slot, player pointer and player data
    cmpwi r3, 0xFF                                      # check if player didnt exist
    beq SaveState_OnDeathCheckInc                       # move on with loop
    # Check for on-death function
    lwz r3, 0x21E0(r5)
    cmpwi r3, 0x0
    bne SaveState_OnDeathCheckExit
    lwz r3, 0x21E4(r5)
    cmpwi r3, 0x0
    bne SaveState_OnDeathCheckExit
    lwz r3, 0x21E8(r5)
    cmpwi r3, 0x0
    bne SaveState_OnDeathCheckExit
    # Check if holding an item
    lwz r3, 0x1974(r5)
    cmpwi r3, 0x0
    bne SaveState_OnDeathCheckExit
    lwz r3, 0x1978(r5)
    cmpwi r3, 0x0
    bne SaveState_OnDeathCheckExit
    # Check for fighter accessory
    lwz r3, 0x20A0(r5)
    cmpwi r3, 0x0
    bne SaveState_OnDeathCheckExit
    b SaveState_OnDeathCheckInc

SaveState_OnDeathCheckExit:
    # PLay Error SFX
    li r3, 0xAF
    bl PlaySFX
    li r3, 0xAF
    bl PlaySFX
    b SaveState_SaveExit

SaveState_OnDeathCheckInc:
    # Check For Subchar Before Looping
    cmpwi REG_isSubchar, 0x1
    beq SaveState_OnDeathCheck_ToggleSubCharOff
    li REG_isSubchar, 0x1
    b SaveState_OnDeathCheckLoop

SaveState_OnDeathCheck_ToggleSubCharOff:
    li REG_isSubchar, 0x0
    addi REG_LoopCount, REG_LoopCount, 0x1
    cmpw REG_LoopCount, REG_PlayerTotal
    blt SaveState_OnDeathCheckLoop

SaveState_SaveLoopInit:
    # Init Save Loop
    li REG_LoopCount, 0x0                               # player ID
    li REG_isSubchar, 0x0                               # main/sub char bool

SaveState_SaveLoop:
    # Get This Player's Backup Pointer in REG_Backup
    mulli r4, REG_LoopCount, 0x8                        # 8 bytes per player pointer
    add REG_Backup, r4, REG_SaveStruct                  # REG_Backup contains this players block backup

    # Check If Backup Exists
    cmpwi REG_isSubchar, 0x0
    beq SaveState_Save_MainChar

SaveState_Save_SubChar:
    lwz r3, 0x4(REG_Backup)                             # get pointer to backup if it exists
    b SaveState_Save_CheckIfExists

SaveState_Save_MainChar:
    lwz r3, 0x0(REG_Backup)                             # get pointer to backup if it exists

SaveState_Save_CheckIfExists:
    cmpwi r3, 0x0
    beq SaveState_SaveStart

    # Remove Old Backup (HSD_Free)
    branchl r12, HSD_Free

SaveState_SaveStart:
    # Get Proper Player Data
    mr r3, REG_LoopCount
    mr r4, REG_isSubchar
    bl SaveState_GetPlayerDataPointer                   # returns player slot, player pointer and player data
    cmpwi r3, 0xFF                                      # check if player didnt exist
    beq SaveState_SaveLoopInc                           # move on with loop
    mr REG_SpawnedOrder, r3                             # REG_SpawnedOrder contains actual player slot
    mr REG_PlayerData, r5                               # REG_PlayerData contains real player block

# Get Player Data Length
SaveState_Save_GetPlayerBlockLength:
    load r3, 0x80458fd0
    lwz REG_PlayerDataSize, 0x20(r3)                    # get player block length in REG_PlayerDataSize
    addi r3, REG_PlayerDataSize, 0x100                  # add static block length
    addi r3, r3, 0x10                                   # add additional storage
    branchl r12, HSD_MemAlloc                           # HSD_MemAlloc

    # Store Pointer To Task Struct
    cmpwi REG_isSubchar, 0x0
    bne Savestate_Save_StoreBackupSubChar
    stw r3, 0x0(REG_Backup)
    b Savestate_Save_StoreBackupEnd

Savestate_Save_StoreBackupSubChar:
    stw r3, 0x4(REG_Backup)

Savestate_Save_StoreBackupEnd:
    mr REG_PlayerData_Backup, r3                        # REG_PlayerData_Backup contains playerblock backup

    # Copy Player Block to Backup
    mr r3, REG_PlayerData_Backup                        # r3 = destination to copy to
    mr r4, REG_PlayerData                               # r4 = source
    mr r5, REG_PlayerDataSize                           # r5 = playerblock length
    branchl r12, memcpy                                 # mempcy

    # Copy Static Block to Backup
    cmpwi REG_isSubchar, 0x0                            # unless this is a subcharacter
    bne Savestate_Save_SkipStaticBlockBackup
    add r3, REG_PlayerDataSize, REG_PlayerData_Backup   # get end of playerblock in r4
    load r4, 0x80453080                                 # get static block in r4
    li r5, 0xE90
    mullw r5, r5, REG_SpawnedOrder
    add r4, r4, r5
    li r5, 0x100                                        # only copying the first 100 bytes
    branchl r12, memcpy                                 # mempcy

Savestate_Save_SkipStaticBlockBackup:
    # Save Camera Flag
    lwz r3, 0x890(REG_PlayerData)
    lwz r3, 0x8(r3)
    add r4, REG_PlayerDataSize, REG_PlayerData_Backup   # get end of player block in r4
    addi r4, r4, 0x100                                  # get end of static block
    stw r3, 0x0(r4)                                     # store to end of block

SaveState_SaveLoopInc:
    # Check For Subchar Before Looping
    cmpwi REG_isSubchar, 0x1
    beq SaveState_SaveLoopInc_ToggleSubCharOff
    li REG_isSubchar, 0x1
    b SaveState_SaveLoop

SaveState_SaveLoopInc_ToggleSubCharOff:
    li REG_isSubchar, 0x0
    addi REG_LoopCount, REG_LoopCount, 0x1
    cmpw REG_LoopCount, REG_PlayerTotal
    blt SaveState_SaveLoop

SaveState_SaveExit:
    restore
    blr

SaveState_Load:
    .set REG_SaveStruct, 31
    .set REG_PlayerTotal, 30
    .set REG_LoopCount, 29
    .set REG_isSubchar, 23
    .set REG_Backup, 28
    .set REG_SpawnedOrder, 22
    .set REG_PlayerGObj, 25
    .set REG_PlayerData, 26
    .set REG_PlayerDataSize, 24
    .set REG_PlayerData_Backup, 27

    backup

    mr REG_SaveStruct, r3

    # Count Players in Match
    branchl r3, 0x8016b558

    # Move Player Number to REG_PlayerTotal
    mr REG_PlayerTotal, r3

# Restore Camera Info Here

    # Init Load Loop
    li REG_LoopCount, 0x0                               # player count
    li REG_isSubchar, 0x0                               # main/subchar bool

SaveState_LoadLoop:
    # Get This Player's Backup Pointer in REG_Backup
    mulli r4, REG_LoopCount, 0x8                        # 8 bytes per player pointer
    add REG_Backup, r4, REG_SaveStruct                  # REG_Backup contains this players block backup

    # Check If Backup Exists
    cmpwi REG_isSubchar, 0x0
    beq SaveState_Load_MainChar

SaveState_Load_SubChar:
    lwz r3, 0x4(REG_Backup)                             # get pointer to backup if it exists
    b SaveState_Load_CheckIfExists

SaveState_Load_MainChar:
    lwz r3, 0x0(REG_Backup)                             # get pointer to backup if it exists

SaveState_Load_CheckIfExists:
    cmpwi r3, 0x0
    beq SaveState_LoadLoopInc

SaveState_LoadStart:
    # Get Proper Player Data
    mr r3, REG_LoopCount
    mr r4, REG_isSubchar
    bl SaveState_GetPlayerDataPointer                   # returns player slot, player pointer and player data
    cmpwi r3, 0xFF                                      # check if player didnt exist
    beq SaveState_LoadLoopInc                           # move on with loop
    mr REG_SpawnedOrder, r3                             # REG_SpawnedOrder contains actual player slot
    mr REG_PlayerGObj, r4                               # REG_PlayerGObj contains external player
    mr REG_PlayerData, r5                               # REG_PlayerData contains real player block

# Get Player Block Length in REG_PlayerDataSize
SaveState_Load_GetPlayerBlockLength:
    load REG_PlayerDataSize, 0x80458fd0
    lwz REG_PlayerDataSize, 0x20(REG_PlayerDataSize)    # REG_PlayerDataSize = length

    # Get Pointer From Task Struct
    cmpwi REG_isSubchar, 0x0                            # check if subcharacter
    beq Savestate_Load_GetBackupMainChar

Savestate_Load_GetBackupSubChar:
    lwz REG_PlayerData_Backup, 0x4(REG_Backup)          # REG_PlayerData_Backup contains playerblock backup
    b Savestate_Load_RestoreFacingDirection

Savestate_Load_GetBackupMainChar:
    lwz REG_PlayerData_Backup, 0x0(REG_Backup)          # REG_PlayerData_Backup contains playerblock backup

# Restore Facing Direction
Savestate_Load_RestoreFacingDirection:
    lwz r3, 0x2C(REG_PlayerData_Backup)                 # backed up Facing Direction
    stw r3, 0x2C(REG_PlayerData)

    # Enter Into Sleep
    mr r3, REG_PlayerGObj
    li r4, 0x0
    branchl r12, AS_Sleep

    # Remove On Death Function Pointer
    li r3, 0x0
    stw r3, 0x21E4(REG_PlayerData)
    stw r3, 0x21E8(REG_PlayerData)

    # Enter Into Backed Up State
    mr r3, REG_PlayerGObj
    lwz r4, 0x10(REG_PlayerData_Backup)                 # backed up AS
    li r5, 0x0
    li r6, 0x0
    lfs f1, 0x894(REG_PlayerData_Backup)                # backed up Frame Number
    lfs f2, 0x89C(REG_PlayerData_Backup)                # backed up Frame Speed
    lfs f3, -0x7548(rtoc)
    # lfs f3, 0x8A4(REG_PlayerData_Backup) #backup up Blend Amount
    branchl r12, ActionStateChange                      # ASC

    # Keep Previous Frame Buttons From Current Block
    lwz r3, 0x620(REG_PlayerData)
    stw r3, 0xD0(sp)
    lwz r3, 0x624(REG_PlayerData)
    stw r3, 0xD4(sp)
    lwz r3, 0x65C(REG_PlayerData)
    stw r3, 0xD8(sp)

    # Keep Collision Bubble Toggles
    lwz r3, 0x21FC(REG_PlayerData)
    stw r3, 0xDC(sp)

    # Copy PlayerBlock Backup to Current
    mr r3, REG_PlayerData
    mr r4, REG_PlayerData_Backup
    mr r5, REG_PlayerDataSize
    branchl r12, memcpy                                 # mempcy

# Zero Blend
# lfs f1, -0x7548(rtoc)
# stfs f1, 0x8A4(REG_PlayerData)

    # Copy Static Block Backup to Current
    cmpwi REG_isSubchar, 0                              # but not if subcharacter
    bne Savestate_Load_SkipStaticBlockRestore
    load r3, 0x80453080                                 # get static block in r3
    li r4, 0xE90
    mullw r4, r4, REG_SpawnedOrder
    add r3, r3, r4
    add r4, REG_PlayerDataSize, REG_PlayerData_Backup   # get end of block in r4
    li r5, 0x100                                        # length is 0x100
    branchl r12, memcpy                                 # mempcy

Savestate_Load_SkipStaticBlockRestore:
    # Restore Previous Frame Buttons From Current Block
    lwz r3, 0xD0(sp)
    stw r3, 0x620(REG_PlayerData)
    stw r3, 0x628(REG_PlayerData)
    lwz r3, 0xD4(sp)
    stw r3, 0x624(REG_PlayerData)
    stw r3, 0x62C(REG_PlayerData)
    lwz r3, 0xD8(sp)
    stw r3, 0x65C(REG_PlayerData)
    stw r3, 0x660(REG_PlayerData)
    stw r3, 0x664(REG_PlayerData)

    # Restore Collision Bubble Toggles
    lwz r3, 0xDC(sp)
    stw r3, 0x21FC(REG_PlayerData)

    # Remove Cached Animation Pointer (This fixes the Fall Animation Bug)
    li r3, 0x0
    stw r3, 0x5A8(REG_PlayerData)

    # Remove Respawn Platform JObj Pointer and Think Function
    stw r3, 0x20A0(REG_PlayerData)
    stw r3, 0x21B0(REG_PlayerData)

    # Remove Held Item Pointer
    stw r3, 0x1974(REG_PlayerData)

    # Update ECB Position
    mr r3, REG_PlayerGObj
    bl UpdatePosition

    # Stop Player's SFX
    mr r3, REG_PlayerData
    branchl r12, SFX_StopAllCharacterSFX

    # Stop Crowd SFX
    branchl r12, SFXManager_StopSFXIfPlaying

    # Remove GFX
    mr r3, REG_PlayerGObj
    branchl r12, GFX_RemoveAll

    /*                                                  # Removing this, causes ground issues when restoring. instead im removing the OSReport call for the error
    # If Grounded, Change Ground Variable Back
    lwz r3, 0xE0(REG_PlayerData)
    cmpwi r3, 0x0
    bne Savestate_RestoreCameraFlag
    li r3, 0x1
    stw r3, 0x83C(REG_PlayerData)
    */

# Restore Camera Flag
Savestate_RestoreCameraFlag:
    add r3, REG_PlayerDataSize, REG_PlayerData_Backup   # get end of block in r4
    addi r3, r3, 0x100                                  # static block length = 0x100
    lwz r3, 0x0(r3)                                     # get flag
    lwz r4, 0x890(REG_PlayerData)
    stw r3, 0x8(r4)

    # Update Camera Box Position
    mr r3, REG_PlayerGObj
    bl UpdateCameraBox

    # Remake HUD For Dead Players (Taken from Achilles' GitHub)
    cmpwi REG_isSubchar, 0x1                            # dont run this on subcharacters
    beq SaveState_HUD_End
    load r3, 0x804a10c8                                 # get base HUD info
    mulli r4, REG_SpawnedOrder, 100                     # get offset
    add r20, r4, r3                                     # get to this player's HUD info
    branchl r12, 0x8016b094                             # MatchInfo_StockModeCheck
    cmpwi r3, 0                                         # if not stock mode
    beq- SaveState_RELOAD_PERCENT_HUDS_NOT_STOCK

SaveState_RELOAD_PERCENT_HUDS_STOCK:
    mr r3, REG_SpawnedOrder                             # get player number
    branchl r12, 0x80033bd8                             # get stocks left
    cmpwi r3, 0
    bne- SaveState_RELOAD_PERCENT_HUDS_NOT_STOCK
    li r5, 0x80                                         # remove percent
    stb r5, 0x10(r20)
    b SaveState_HUD_End

SaveState_RELOAD_PERCENT_HUDS_NOT_STOCK:
    lbz r5, 0x10(r20)
    rlwinm. r5, r5, 0, 24, 24                           # (00000080), is player HUD percent gone?
    beq- SaveState_HUD_End

SaveState_REMAKE_PERCENT:
    .set HUD_PlayerCreate_Prefunction, 0x802f6e1c
    mr r3, REG_SpawnedOrder
    branchl r4, HUD_PlayerCreate_Prefunction

SaveState_HUD_End:
SaveState_LoadLoopInc:
    # Check For Subchar Before Looping
    cmpwi REG_isSubchar, 0x1
    beq SaveState_LoadLoopInc_ToggleSubCharOff
    li REG_isSubchar, 0x1
    b SaveState_LoadLoop

SaveState_LoadLoopInc_ToggleSubCharOff:
    li REG_isSubchar, 0x0
    addi REG_LoopCount, REG_LoopCount, 0x1
    cmpw REG_LoopCount, REG_PlayerTotal
    blt SaveState_LoadLoop

SaveState_LoadEnd:
    /*

SaveState_Load_RemoveAllGFX:
    # Get First GFX
    lwz r3, -0x3E74(r13)
    lwz r20, 0x30(r3)

# Check if exists
SaveState_Load_CheckIfGFXExists:
    cmpwi r20, 0
    beq SaveState_Load_RemoveAllGFXEnd
    # Check if this is a particle GObj?
    lbz r3, 0x4(r20)
    cmpwi r3, 1
    beq SaveState_Load_GetNextGFX
    # Remove this GFX
    mr r3, r20
    branchl r12, 0x80390228

# Get next GFX
SaveState_Load_GetNextGFX:
    lwz r20, 0x8(r20)
    b SaveState_Load_CheckIfGFXExists

SaveState_Load_RemoveAllGFXEnd:
    */

SaveState_LoadExit:
    restore
    blr

#########################################################################

############################
## Get PlayerData Pointer ##
############################

SaveState_GetPlayerDataPointer:
# r3 = player number (regardless of port)
# r4 = 0x0 for main char // 0x1 for subchar

    # returns:
    # r3 = player slot
    # r4 = external player
    # r5 = internal player
    subi sp, sp, 0x8
    mr r11, r3                                          # move desired player into r11
    mr r10, r4                                          # move subchar status into r4
    mr r9, sp                                           # move bytefield into r10
    li r3, -0x1                                         # zero out new space
    stw r3, 0x0(r9)
    stw r3, 0x4(r9)

    # Make Bytefield For Player Order
    li r7, 0x0                                          # init loop
    li r6, 0x0                                          # init player ID
    load r5, 0x80453080                                 # first playerblock

SaveState_GetPlayerDataPointer_LoopStart:
    lwz r3, 0x0(r5)                                     # an inactive player block will store "0" at offset 0x0
    cmpwi r3, 0x0
    beq SaveState_GetPlayerDataPointer_Empty

SaveState_GetPlayerDataPointer_PlayerPresent:
    stbx r7, r6, r9                                     # store loop count to player ID offset
    addi r6, r6, 0x1                                    # next player ID

SaveState_GetPlayerDataPointer_Empty:
    addi r5, r5, 0xe90                                  # next playerblock
    addi r7, r7, 0x1                                    # inc loop
    cmpwi r7, 6
    blt SaveState_GetPlayerDataPointer_LoopStart

    # Now r9 contains player bytefield
    lbzx r3, r11, r9                                    # get the correct player slot for the X player
    cmpwi r3, 0xFF                                      # check if player exists
    beq SaveState_GetPlayerDataPointer_Exit             # if not exit with -1 return

    load r5, 0x80453080                                 # first playerblock
    mulli r4, r3, 0xe90                                 # get offset
    add r4, r4, r5                                      # get static block in r4

    cmpwi r10, 0x0
    beq SaveState_GetPlayerDataPointer_MainChar

SaveState_GetPlayerDataPointer_SubChar:
    lwz r4, 0xB4(r4)
    b SaveState_GetPlayerDataPointer_LoadInternal

SaveState_GetPlayerDataPointer_MainChar:
    lwz r4, 0xB0(r4)

SaveState_GetPlayerDataPointer_LoadInternal:
    # Check If Player Exists
    cmpwi r4, 0x0
    bne SaveState_GetPlayerDataPointer_LoadInternalContinue
    li r3, 0xFF
    b SaveState_GetPlayerDataPointer_Exit

SaveState_GetPlayerDataPointer_LoadInternalContinue:
    lwz r5, 0x2c(r4)

SaveState_GetPlayerDataPointer_Exit:
    addi sp, sp, 0x8
    blr

#######################################################

CheckForSaveAndLoad:
    .set LoopCount, 31

    backup

    mr r29, r3                                          # Task Data

    # Init Loop
    li LoopCount, 0

# Loop
CheckForSaveAndLoad_Loop:
    mr r3, LoopCount
    branchl r12, PlayerBlock_LoadMainCharDataOffset
    cmpwi r3, 0x0
    beq CheckForSaveAndLoad_Inc

CheckForSaveAndLoad_CheckInputs:
    load r3, 0x804c21cc
    # load r3, 0x804c1fac
    mulli r0, LoopCount, 68
    add r4, r3, r0
    # Make Sure Nothing Else Is Held
    lhz r3, 0x2(r4)
    rlwinm. r0, r3, 0, 0, 26
    bne CheckForSaveAndLoad_Inc
    lwz r3, 0x8(r4)
    rlwinm. r0, r3, 0, 30, 30
    beq CheckForSaveAndLoad_NoSave
    mr r3, r29
    li r4, 0                                            # run failsafe code
    bl SaveState_Save
    li r3, 0x0
    b CheckForSaveAndLoad_Exit

CheckForSaveAndLoad_NoSave:
    rlwinm. r0, r3, 0, 31, 31
    beq CheckForSaveAndLoad_Inc
    mr r3, r29
    bl SaveState_Load
    mr r3, r29
    bl SaveState_Load
    li r3, 0x1
    b CheckForSaveAndLoad_Exit

CheckForSaveAndLoad_Inc:
    addi LoopCount, LoopCount, 1
    cmpwi LoopCount, 4
    blt CheckForSaveAndLoad_Loop

CheckForSaveAndLoad_Exit:
    restore
    blr

############################################

GiveFullShields:
    backup

GiveFullShields_GetFirstPlayer:
    lwz r3, -0x3E74(r13)
    lwz r20, 0x0020(r3)
    b GiveFullShields_CheckIfPlayerExists

GiveFullShields_GetNextPlayer:
    lwz r20, 0x8(r20)

GiveFullShields_CheckIfPlayerExists:
    cmpwi r20, 0x0
    beq GiveFullShields_Exit
    lwz r21, 0x2C(r20)

    # Give Full Shield
    lwz r3, -0x514C(r13)
    lfs f0, 0x0260(r3)
    stfs f0, 0x1998(r21)
    b GiveFullShields_GetNextPlayer

GiveFullShields_Exit:
    restore
    blr

############################################

UpdateAllGFX:
    backup

    mr r3, 30
    branchl r12, GFX_UpdatePlayerGFX

    # Check For Follower
    mr r3, r30
    bl CheckIfPlayerHasAFollower
    cmpwi r3, 0x0
    beq UpdateAllGFX_Exit

    # Apply To Follower Char
    branchl r12, GFX_UpdatePlayerGFX

UpdateAllGFX_Exit:
    restore
    blr

############################################

GiveInvincibility:
# r3 = ext pointer
# r4 = frames

    backup

    # Give To Main Char
    mr r31, r3
    mr r30, r4
    branchl r12, ApplyInvincibility

    # Check For Follower
    mr r3, r31
    bl CheckIfPlayerHasAFollower
    cmpwi r3, 0x0
    beq GiveInvincibility_Exit

    # Apply To Follower Char
    mr r4, r30
    branchl r12, ApplyInvincibility

GiveInvincibility_Exit:
    restore
    blr

############################################
StoreCPUTypeAndZeroInputs:
# Set P2 AI Type to None
# li r3, 0xF
# stw r3, 0x1A94(r29)

    # Clear Inputs For P2 CPU
    li r3, 0x0
    stw r3, 0x1A88(r29)
    stw r3, 0x1A8C(r29)
    sth r3, 0x1A90(r29)
    blr

###########################################

ClearNanaInputs:
    backup

    # Clear Inputs if P1 is Ice Climbers
    mr r3, 28
    bl CheckIfPlayerHasAFollower
    cmpwi r3, 0x0
    beq ClearNanaInputs_P2
    li r3, 0x0
    stw r3, 0x1A88(r4)
    stw r3, 0x1A8C(r4)

# Clear Inputs if P2 is Ice Climbers
ClearNanaInputs_P2:
    mr r3, 30
    bl CheckIfPlayerHasAFollower
    cmpwi r3, 0x0
    beq ClearNanaInputs_Exit
    li r3, 0x0
    stw r3, 0x1A88(r4)
    stw r3, 0x1A8C(r4)

ClearNanaInputs_Exit:
    restore
    blr

###########################################

CheckIfFirstFrame:
    lwz r3, TM_GameFrameCounter(r13)
    cmpwi r3, 0x1
    bne CheckIfFirstFrame_False
    li r3, 0x1
    b CheckIfFirstFrame_Exit

CheckIfFirstFrame_False:
    li r3, 0x0

CheckIfFirstFrame_Exit:
    blr

#############################################

CurrentInputsAsLastFramesInputs:
    load r3, 0x804c21cc
    lwz r3, 0x0(r3)
    stw r3, 0x65C(r27)
    stw r3, 0x664(r27)

    # Check For Z Press
    rlwinm. r0, r3, 0, 27, 27
    beq CurrentInputsAsLastFramesInputs_Exit
    oris r0, r3, 0x8000
    ori r0, r0, 0x0100
    stw r0, 0x65C(r27)
    stw r0, 0x664(r27)

CurrentInputsAsLastFramesInputs_Exit:
    blr

#############################################

    /*

CPUActions_MultiShine:
    backup

    mr r29, r3

    # Get AS and Frame Number
    lwz r4, 0x10(r3)                                    # Get Current AS

    # Start - Check to Grounded Shine
    cmpwi r4, 0xE                                       # Wait
    beq Multishine_StartShine
    cmpwi r4, 0x169                                     # Shine Loop Ground
    beq Multishine_JumpCancelShine
    cmpwi r4, 0x19                                      # JumpF
    beq Multishine_StartShine
    b CPUActions_MultiShine_Exit

Multishine_StartShine:
    li r3, -127                                         # Down
    stb r3, 0x1A8D(r29)                                 # Analog Y
    li r3, 0x200                                        # B
    stw r3, 0x1A88(r29)                                 # Inputs
    b CPUActions_MultiShine_Exit

Multishine_JumpCancelShine:
    li r3, 0x800                                        # X
    stw r3, 0x1A88(r29)                                 # Inputs
    b CPUActions_MultiShine_Exit

Multishine_ShineAir:
    b CPUActions_MultiShine_Exit

CPUActions_MultiShine_Exit:
    restore
    blr

    */

###################################

RAndDPadChangesEventOption:

OptionWindow:
# in
# r3 = pointer to option byte in memory
# r4 = pointer to Window and Option Count
# r5 = pointer to ASCII struct

# out
# r3 =

    .set TextCreateFunction, 0x80005928
    .set OptionWindowMemory, 20
    .set OptionTextInfo, 21
    .set OptionASCII, 22
    .set text, 23
    .set toggledBool, 28
    .set toggledOption, 29

    backup

    # Backup Parameters
    mr OptionWindowMemory, r3                           # pointer to option byte in memory
    mr OptionTextInfo, r4                               # pointer to Window and Option Count
    mr OptionASCII, r5                                  # pointer to ASCII struct

    # Initialize Toggled Bools
    li toggledBool, 0
    li toggledOption, -1

    # Get Number Of Options Onscreen At Once (1, 2, or 3)
    lbz r24, 0x0(OptionTextInfo)                        # Get Number of Different Windows
    cmpwi r24, 2                                        # Check If Over 3
    ble 0x8
    li r24, 2                                           # Make 3

    # Get Pausing Player's Inputs
    load r3, 0x8046b6a0
    lbz r3, 0x1(r3)
    load r4, 0x804c1fac
    mulli r3, r3, 68
    add r3, r3, r4
    lwz r3, 0x8(r3)

    # Check For DPad Up And Down
    cmpwi r3, 0x04
    beq RAndDPadChangesEventOption_CursorDown
    cmpwi r3, 0x08
    beq RAndDPadChangesEventOption_CursorUp
    b RAndDPadChangesEventOption_CheckDPadLeftAndRight

RAndDPadChangesEventOption_CursorUp:
    # Update Cursor Position
    lbz r3, 0x0(OptionWindowMemory)                     # Get Current Cursor Position Byte
    subi r3, r3, 0x1                                    # Subtract by 1
    stb r3, 0x0(OptionWindowMemory)
    cmpwi r3, 0x0
    bge RAndDPadChangesEventOption_PlayScrollSFX
    # Cursor Stays at the top of the screen
    li r3, 0
    stb r3, 0x0(OptionWindowMemory)
    # Check To Scroll Down
    # Get Current Window ID(cursor + scroll)
    lbz r3, 0x0(OptionWindowMemory)
    lbz r4, 0x1(OptionWindowMemory)
    add r3, r3, r4
    # Check If This is the Beginning
    cmpwi r3, 0
    ble RAndDPadChangesEventOption_DisplayWindow
    # Scroll Down
    lbz r4, 0x1(OptionWindowMemory)
    subi r4, r4, 1
    stb r4, 0x1(OptionWindowMemory)
    b RAndDPadChangesEventOption_PlayScrollSFX

    b RAndDPadChangesEventOption_DisplayWindow

RAndDPadChangesEventOption_CursorDown:
    # Update Cursor Position
    lbz r3, 0x0(OptionWindowMemory)                     # Get Current Option Byte
    addi r3, r3, 0x1                                    # Add 1
    stb r3, 0x0(OptionWindowMemory)
    cmpw r3, r24
    ble RAndDPadChangesEventOption_PlayScrollSFX
    # Cursor Stays at the Bottom of the Screen
    stb r24, 0x0(OptionWindowMemory)
    # Check To Scroll Down
    # Get Current Window ID(cursor + scroll)
    lbz r3, 0x0(OptionWindowMemory)
    lbz r4, 0x1(OptionWindowMemory)
    add r3, r3, r4
    # Get Max Number Of Windows
    lbz r4, 0x0(OptionTextInfo)                         # Get Number of Different Windows
    # Check If This is the End
    cmpw r3, r4
    bge RAndDPadChangesEventOption_DisplayWindow
    # Scroll Down
    lbz r4, 0x1(OptionWindowMemory)
    addi r4, r4, 1
    stb r4, 0x1(OptionWindowMemory)

    b RAndDPadChangesEventOption_PlayScrollSFX

# Check For DPad Left And Right
RAndDPadChangesEventOption_CheckDPadLeftAndRight:
    cmpwi r3, 0x02
    beq RAndDPadChangesEventOption_Increment
    cmpwi r3, 0x01
    beq RAndDPadChangesEventOption_Decrement
    b RAndDPadChangesEventOption_DisplayWindow

RAndDPadChangesEventOption_Increment:
    # Get Current Window ID(cursor + scroll)
    lbz r3, 0x0(OptionWindowMemory)
    lbz r4, 0x1(OptionWindowMemory)
    add r3, r3, r4
    # Set as Toggled
    li toggledBool, 1
    mr toggledOption, r3

    addi r5, r3, 2
    lbzx r3, r5, OptionWindowMemory                     # Get Current Option Byte
    addi r3, r3, 0x1
    stbx r3, r5, OptionWindowMemory                     # Store New Option Byte Value
    subi r5, r5, 1
    lbzx r4, r5, OptionTextInfo                         # Get Window's Option Byte Max Value
    cmpw r3, r4
    ble RAndDPadChangesEventOption_PlayScrollSFX
    li r3, 0x0
    addi r5, r5, 1
    stbx r3, r5, OptionWindowMemory                     # Get New Option Byte Value
    b RAndDPadChangesEventOption_PlayScrollSFX

RAndDPadChangesEventOption_Decrement:
    # Get Current Window ID(cursor + scroll)
    lbz r3, 0x0(OptionWindowMemory)
    lbz r4, 0x1(OptionWindowMemory)
    add r3, r3, r4
    # Set as Toggled
    li toggledBool, 1
    mr toggledOption, r3

    addi r5, r3, 0x2
    lbzx r3, r5, OptionWindowMemory                     # Get Current Option Byte
    subi r3, r3, 0x1
    stbx r3, r5, OptionWindowMemory                     # Store New Option Byte Value
    cmpwi r3, 0x0
    bge RAndDPadChangesEventOption_PlayScrollSFX
    subi r5, r5, 1
    lbzx r3, r5, OptionTextInfo                         # Get Window's Option Byte Max Value
    addi r5, r5, 1
    stbx r3, r5, OptionWindowMemory                     # Store New Option Byte Value
    b RAndDPadChangesEventOption_PlayScrollSFX

RAndDPadChangesEventOption_PlayScrollSFX:
    li r3, 0x2
    branchl r12, SFX_MenuCommonSound

RAndDPadChangesEventOption_DisplayWindow:
    # Display Text For The New Option Value
    mr r3, r27                                          # p1(no offsetting window)
    li r4, 1                                            # text timeout
    li r5, 0x2                                          # window instance #3
    li r6, 0                                            # window ID #3
    branchl r12, TextCreateFunction                     # create text custom function
    mr text, r3                                         # backup text pointer

#########################
## Display Option Menu ##
#########################

    # Check How Many Options In The Menu
    cmpwi r24, 0
    beq RAndDPadChangesEventOption_DisplayWindow_LoopInit

    # Change Background Size
    bl RAndDPadChangesEventOption_Floats
    mflr r5
    lfs f1, 0x0(r5)                                     # 12.5
    addi r5, r5, 0x4                                    # Skip Window X
    subi r6, r24, 1                                     # Zero Index
    mulli r6, r6, 0x4                                   # Get Y Offset
    lfsx f2, r6, r5
    li r4, 0
    branchl r12, Text_UpdateSubtextSize

    # Move Window
    bl RAndDPadChangesEventOption_Floats
    mflr r5
    lfs f1, -0x37B4(rtoc)
    addi r5, r5, 0xC                                    # Skip Window X and Window Y's
    subi r6, r24, 1                                     # Zero Index
    mulli r6, r6, 0x4                                   # Get Y Offset
    lfsx f2, r6, r5
    mr r3, text
    li r4, 0
    branchl r12, Text_UpdateSubtextPosition

############################
## Display Up/Down Arrows ##
############################

    # Check if at the top of the screen
    lbz r3, 0x1(r20)
    cmpwi r3, 0x0
    beq RAndDPadChangesEventOption_DisplayDownArrow
    # Create Title Text
    li r3, -20                                          # Y
    bl IntToFloat
    fmr f2, f1
    li r3, -210                                         # X
    bl IntToFloat
    mr r3, text                                         # text pointer
    bl RAndDPadChangesEventOption_UpArrowText
    mflr r4
    branchl r12, Text_InitializeSubtext

RAndDPadChangesEventOption_DisplayDownArrow:
    # Check if at the bottom of the screen
    lbz r3, 0x0(r21)
    cmpwi r3, 2
    blt RAndDPadChangesEventOption_DisplayArrowExit
    lbz r4, 0x1(r20)
    sub r3, r3, r4
    cmpwi r3, 2
    ble RAndDPadChangesEventOption_DisplayArrowExit
    # Create Title Text
    li r3, 320                                          # Y value
    bl IntToFloat
    fmr f2, f1
    li r3, -210                                         # X Value
    bl IntToFloat
    mr r3, text                                         # text pointer
    bl RAndDPadChangesEventOption_DownArrowText
    mflr r4
    branchl r12, Text_InitializeSubtext

RAndDPadChangesEventOption_DisplayArrowExit:
############################
## Print Each Option Loop ##
############################

RAndDPadChangesEventOption_DisplayWindow_LoopInit:
    li r27, 0                                           # Init Loop

RAndDPadChangesEventOption_DisplayWindow_Loop:
    # Get Window Title And Option
    mr r3, OptionASCII                                  # Option ASCII Start
    lbz r4, 0x1(OptionWindowMemory)                     # Get Scroll Position
    add r4, r4, r27                                     # Get Loop Count's Window
    addi r5, OptionWindowMemory, 0x2                    # Selection ID's
    lbzx r5, r4, r5                                     # Get Current Option This Window is On
    bl RAndDPadChangesEventOption_GetOptionASCII
    mr r25, r3
    mr r26, r4

    # Create Title Text
    lfs f2, -0x37B4(rtoc)                               # default text Y
    li r3, 120
    mullw r3, r3, r27
    bl IntToFloat
    fadds f2, f1, f2
    lfs f1, -0x37B4(rtoc)                               # default text X
    mr r3, text                                         # text pointer
    mr r4, r25                                          # Title Text Pointer
    branchl r12, Text_InitializeSubtext
    # Make Text Grey
    load r4, 0xdfdfdf00
    stw r4, 0xF0(sp)
    addi r5, sp, 0xF0
    mr r4, r3
    mr r3, text
    branchl r12, Text_ChangeTextColor

    # Create Selection Text
    lfs f2, -0x37B0(rtoc)                               # shift down on Y axis
    li r3, 120
    mullw r3, r3, r27
    bl IntToFloat
    fadds f2, f1, f2
    lfs f1, -0x37B4(rtoc)                               # default text X/Y
    mr r3, text                                         # text pointer
    mr r4, r26                                          # Selection Text
    branchl r12, Text_InitializeSubtext
    # Check To Outline in Yellow
    lbz r4, 0x0(OptionWindowMemory)                     # Get Cursor Position
    cmpw r4, r27                                        # Compare With Loop Counter
    bne RAndDPadChangesEventOption_DisplayWindow_SkipColor
    load r4, 0xf7ff2700
    stw r4, 0xF0(sp)
    addi r5, sp, 0xF0
    mr r4, r3
    mr r3, text
    branchl r12, Text_ChangeTextColor

RAndDPadChangesEventOption_DisplayWindow_SkipColor:
    cmpw r27, r24
    addi r27, r27, 1
    blt RAndDPadChangesEventOption_DisplayWindow_Loop

    b RAndDPadChangesEventOption_Exit

#########################################

RAndDPadChangesEventOption_GetOptionASCII:
    backup

    mr r31, r3                                          # Option ASCII Start
    mr r30, r4                                          # Option ID We're Looking For
    mr r29, r5                                          # Option Selection We're Looking For

    # Init Loop
    li r27, 0

RAndDPadChangesEventOption_GetOptionASCII_OptionIDLoop:
    cmpw r27, r30                                       # Check If This is the Window We're Looking For
    beq RAndDPadChangesEventOption_GetOptionASCII_GetOptionSelection

########################
## Skip Entire Option ##
########################

RAndDPadChangesEventOption_GetOptionASCII_GetNextOptionID:
    # Skip Past Window Title
    mr r3, r31
    bl RAndDPadChangesEventOption_GetNextString
    mr r31, r3                                          # Backup New Pointer

    # Loop Through All The Window's Selections
    li r26, 0                                           # Loop Count

RAndDPadChangesEventOption_GetOptionASCII_LoopThroughSelections:
    # Get This Options (r27) Total Number of Selections (Pointer in OptionTextInfo)
    addi r3, OptionTextInfo, 0x1                        # Get to Option Selection Counts
    lbzx r3, r3, r27                                    # Get This Windows Total Number of Selections
    addi r3, r3, 0x1                                    # Add 1 To Ensure We Are at the Start of the Next Window Title
    cmpw r3, r26                                        # Check If This is the Last Selection
    bne RAndDPadChangesEventOption_GetOptionASCII_LoopThroughSelections_NextSelection

    # End of Loop, Done With This Option
    # Increment Loop Count
    addi r27, r27, 1                                    # Increment Option Count
    b RAndDPadChangesEventOption_GetOptionASCII_OptionIDLoop

RAndDPadChangesEventOption_GetOptionASCII_LoopThroughSelections_NextSelection:
    # Get Next Selection
    mr r3, r31
    bl RAndDPadChangesEventOption_GetNextString
    mr r31, r3                                          # Backup New Pointer
    # Increment Loop Count
    addi r26, r26, 1
    b RAndDPadChangesEventOption_GetOptionASCII_LoopThroughSelections

###########################
## Find Option Selection ##
###########################

RAndDPadChangesEventOption_GetOptionASCII_GetOptionSelection:
    # Init Loop Count + Backup Window Title
    li r26, 0                                           # Init Loop Count
    mr r25, r31                                         # r25 = Window Title
    # Skip Window Title
    mr r3, r31
    bl RAndDPadChangesEventOption_GetNextString
    mr r31, r3                                          # Backup New Pointer

RAndDPadChangesEventOption_GetOptionASCII_GetOptionSelection_Loop:
    # Check If This is the Selection We're Looking For
    cmpw r26, r29
    beq RAndDPadChangesEventOption_GetOptionASCII_GetOptionSelection_Done
    # Get Next Selection
    # Strlen the entry
    mr r3, r31
    bl RAndDPadChangesEventOption_GetNextString
    mr r31, r3                                          # Backup New Pointer
    # Increment Loop Count
    addi r26, r26, 1
    b RAndDPadChangesEventOption_GetOptionASCII_GetOptionSelection_Loop

RAndDPadChangesEventOption_GetOptionASCII_GetOptionSelection_Done:
    mr r3, r25                                          # Return Window Name
    mr r4, r31                                          # Return Selection String

RAndDPadChangesEventOption_GetOptionASCII_Exit:
    restore
    blr

#########################################

RAndDPadChangesEventOption_GetNextString:
    backup

    mr r31, r3                                          # Backup String Pointer
    branchl r12, strlen                                 # Get Length
    add r3, r3, r31                                     # Get End of String

# From here, mini loop to find the next non-zero value.
RAndDPadChangesEventOption_GetNextString_Loop:
    lbzu r4, 0x1(r3)
    cmpwi r4, 0x0
    beq RAndDPadChangesEventOption_GetNextString_Loop

    restore
    blr

#########################################
RAndDPadChangesEventOption_Floats:
    blrl

    .float 16                                           # 12.5, X position
    .long 0x427c0000                                    # 63, 2 Window Y Scale
    .long 0x42bc0000                                    # 94, 3 Window Y Scale
    .long 0xc4610000                                    # -900, 2 Window Y position
    .long 0xc4a8c000                                    # -1350, 3 Window Y position

#########################################
RAndDPadChangesEventOption_UpArrowText:
    blrl

    .string "^"
    .align 2

RAndDPadChangesEventOption_DownArrowText:
    blrl

    .string "v"
    .align 2

#########################################

RAndDPadChangesEventOption_Exit:
    mr r3, toggledBool
    mr r4, toggledOption
    restore
    blr

##################################

DPadCPUPercent:
    backup

    .set REG_SaveStruct, 31
    .set REG_PercentInt, 30
    .set REG_isSubcharBool, 29

    # Backup savestate struct
    mr REG_SaveStruct, r3

    # Get P1 Block
    li r3, 0x0
    branchl r12, PlayerBlock_LoadMainCharDataOffset     # get player block
    lwz r3, 0x2C(r3)

    # Get P2 Percent
    load r6, 0x80453F10
    lhz REG_PercentInt, 0x60(r6)

    # Get Subchar Bool
    lbz REG_isSubcharBool, 0xC(r6)

    # Get inputs
    load r4, 0x804c21cc
    lbz r3, 0x618(r3)
    mulli r0, r3, 68
    add r5, r4, r0
    # Ensure L is pressed (either digital or lightshield)
    lwz r3, 0x0(r5)                                     # get held inputs
    rlwinm. r0, r3, 0, 25, 25
    bne DPadCPUPercent_Start
    lbz r3, 0x1c(r5)                                    # get trigger
    cmpwi r3, 24
    blt DPadCPUPercent_Exit

DPadCPUPercent_Start:
    # Check DPad
    lwz r3, 0xC(r5)                                     # get rapid inputs
    rlwinm. r0, r3, 0, 30, 30
    bne DPadCPUPercent_IncByOne
    rlwinm. r0, r3, 0, 31, 31
    bne DPadCPUPercent_DecByOne
    rlwinm. r0, r3, 0, 28, 28
    bne DPadCPUPercent_IncByTen
    rlwinm. r0, r3, 0, 29, 29
    bne DPadCPUPercent_DecByTen
    b DPadCPUPercent_Exit

DPadCPUPercent_IncByOne:
    cmpwi REG_PercentInt, 999
    blt DPadCPUPercent_IncByOneReal
    li REG_PercentInt, 999
    b DPadCPUPercent_StorePercent

DPadCPUPercent_IncByOneReal:
    addi REG_PercentInt, REG_PercentInt, 0x1
    b DPadCPUPercent_StorePercent

DPadCPUPercent_DecByOne:
    cmpwi REG_PercentInt, 0
    bgt DPadCPUPercent_DecByOneReal
    li REG_PercentInt, 0
    b DPadCPUPercent_StorePercent

DPadCPUPercent_DecByOneReal:
    subi REG_PercentInt, REG_PercentInt, 0x1
    b DPadCPUPercent_StorePercent

DPadCPUPercent_IncByTen:
    cmpwi REG_PercentInt, 989
    blt DPadCPUPercent_IncByTenReal
    li REG_PercentInt, 999
    b DPadCPUPercent_StorePercent

DPadCPUPercent_IncByTenReal:
    addi REG_PercentInt, REG_PercentInt, 10
    b DPadCPUPercent_StorePercent

DPadCPUPercent_DecByTen:
    cmpwi REG_PercentInt, 9
    bgt DPadCPUPercent_DecByTenReal
    li REG_PercentInt, 0
    b DPadCPUPercent_StorePercent

DPadCPUPercent_DecByTenReal:
    subi REG_PercentInt, REG_PercentInt, 10
    b DPadCPUPercent_StorePercent

DPadCPUPercent_StorePercent:
    # Store to Active Static Playerblock
    sth REG_PercentInt, 0x60(r6)
    # Convert to Float
    mr r3, REG_PercentInt
    bl IntToFloat
    # Active PlayerData
    li r3, 0x1
    branchl r12, PlayerBlock_LoadMainCharDataOffset     # get player block
    lwz r3, 0x2C(r3)
    stfs f1, 0x1830(r3)

    # Backed Up PlayerData
    mulli r4, REG_isSubcharBool, 0x4
    lwzx r3, r4, REG_SaveStruct
    stfs f1, 0x1830(r3)
    # Backed Up Static Playerblock
    load r4, 0x80458fd0                                 # get player block length
    lwz r4, 0x20(r4)                                    # get player block length
    lwz r3, 0x0(REG_SaveStruct)                         # only the main character has a static block backup
    add r3, r3, r4                                      # static block start
    sth REG_PercentInt, 0x60(r3)
    sth REG_PercentInt, 0x62(r3)

DPadCPUPercent_Exit:
    restore
    blr

##################################

InitializePositions:
    backup

    # Move Float Pointer
    mr r20, r3

    # P1 Static Block
    load r22, 0x80453080
    # P2 Static Block
    addi r23, r22, 0xE90

    # Move P1
    mr r3, r28
    branchl r12, 0x8008a2bc                             # Enter Wait
    lfs f1, 0x0(r20)
    stfs f1, 0xB0(r27)
    lfs f1, 0x8(r20)
    stfs f1, 0xB4(r27)
    mr r3, r28
    bl UpdatePosition
    mr r3, r28
    bl UpdateCameraBox
    mr r3, r28
    bl CheckIfPlayerHasAFollower
    cmpwi r3, 0x0
    beq InitializePositions_MoveP2
    # Move This Char Too
    mr r24, r3
    mr r25, r4
    mr r3, r24
    branchl r12, 0x8008a2bc                             # Enter Wait
    lfs f1, 0x0(r20)
    stfs f1, 0xB0(r25)
    lfs f1, 0x8(r20)
    stfs f1, 0xB4(r25)
    mr r3, r24
    bl UpdatePosition
    mr r3, r24
    bl UpdateCameraBox

# Move P2
InitializePositions_MoveP2:
    mr r3, r30
    branchl r12, 0x8008a2bc                             # Enter Wait
    lfs f1, 0x4(r20)
    stfs f1, 0xB0(r29)
    lfs f1, 0xC(r20)
    stfs f1, 0xB4(r29)
    mr r3, r30
    bl UpdatePosition
    mr r3, r30
    bl UpdateCameraBox
    mr r3, r30
    bl CheckIfPlayerHasAFollower
    cmpwi r3, 0x0
    beq InitializePositions_Exit
    # Move This Char Too
    mr r24, r3
    mr r25, r4
    mr r3, r24
    branchl r12, 0x8008a2bc                             # Enter Wait
    lfs f1, 0x4(r20)
    stfs f1, 0xB0(r25)
    lfs f1, 0xC(r20)
    stfs f1, 0xB4(r25)
    mr r3, r24
    bl UpdatePosition
    mr r3, r24
    bl UpdateCameraBox

InitializePositions_Exit:
    bl ClearNanaInputs
    bl CurrentInputsAsLastFramesInputs

    restore
    blr

#########################################################

CheckIfPlayerHasAFollower:
# Returns
# r3 = 0 for no follower // External Pointer
# r4 = 0 for no follower // Internal Pointer

    backup

    # Get Players Data
    lwz r31, 0x2C(r3)

    # Get Player Slot
    lbz r3, 0xC(r31)
    li r4, 0x1
    bl SaveState_GetPlayerDataPointer                   # returns r3=Slot/-1 if subchar doesnt exist, r4= external, r5=internal
    cmpwi r3, 0xFF
    beq CheckIfPlayerHasAFollower_NoFollower

    # Check If Follower
    mr r24, r4
    mr r25, r5
    lbz r3, 0xC(r25)                                    # get slot
    branchl r12, 0x80032330                             # get external character ID
    load r4, pdLoadCommonData                           # pdLoadCommonData table
    mulli r0, r3, 3                                     # struct length
    add r3, r4, r0                                      # get characters entry
    lbz r0, 0x2(r3)                                     # get subchar functionality
    cmpwi r0, 0x0                                       # if not a follower, exit
    bne CheckIfPlayerHasAFollower_NoFollower

    # Return Follower Pointers
    mr r3, r24                                          # External
    mr r4, r25                                          # Internal
    b CheckIfPlayerHasAFollower_Exit

CheckIfPlayerHasAFollower_NoFollower:
    li r3, 0x0
    li r4, 0x0

CheckIfPlayerHasAFollower_Exit:
    restore
    blr

#########################################################

Randomize_LeftorRightSide:
# r3 = 0 = Same Side of Stage // 1 = Opposing Sides of Stage

    backup

    mr r20, r3                                          # Backup Stage Side Bool

    # Get Left or Right Side
    li r3, 2
    branchl r12, HSD_Randi
    # Check To Negate
    cmpwi r3, 0x0                                       # 0 = Left, 1 = Right
    bne Randomize_RightSide

Randomize_LeftSide:
    # P1 X Position
    lwz r3, 0x10(r31)                                   # P1 Backup Start
    lwz r4, 0x18(r31)                                   # P2 Backup Start
    lfs f1, 0xB0(r3)                                    # P1 Backup X Pos
    cmpwi r20, 0x0
    beq 0xC
    bl Randomize_AlwaysNegative
    b 0x8
    bl Randomize_AlwaysNegative
    stfs f1, 0xB0(r3)                                   # P1 Backup X Pos
    # P2 X Position
    lfs f1, 0xB0(r4)                                    # P2 Backup X Pos
    cmpwi r20, 0x0
    beq 0xC
    bl Randomize_AlwaysPositive
    b 0x8
    bl Randomize_AlwaysNegative
    stfs f1, 0xB0(r4)                                   # P2 Backup X Pos
    # Facing Directions
    lis r5, 0x3f80                                      # P1 Face Right
    lis r6, 0xbf80                                      # P2 Face Left
    stw r5, 0x2C(r3)                                    # P1 Backup Facing
    stw r6, 0x2C(r4)                                    # P2 Facing
    b Randomize_LeftorRightSide_CheckForFollowers

Randomize_RightSide:
    # P1 X Position
    lwz r3, 0x10(r31)                                   # P1 Backup Start
    lwz r4, 0x18(r31)                                   # P2 Backup Start
    lfs f1, 0xB0(r3)                                    # P1 Backup X Pos
    cmpwi r20, 0x0
    beq 0xC
    bl Randomize_AlwaysPositive
    b 0x8
    bl Randomize_AlwaysPositive
    stfs f1, 0xB0(r3)                                   # P1 Backup X Pos
    # P2 X Position
    lfs f1, 0xB0(r4)                                    # P2 Backup X Pos
    cmpwi r20, 0x0
    beq 0xC
    bl Randomize_AlwaysNegative
    b 0x8
    bl Randomize_AlwaysPositive
    stfs f1, 0xB0(r4)                                   # P2 Backup X Pos
    # Facing Directions
    lis r5, 0xbf80                                      # P1 Face Left
    lis r6, 0x3f80                                      # P2 Face Right
    stw r5, 0x2C(r3)                                    # P1 Backup Facing
    stw r6, 0x2C(r4)                                    # P2 Facing

Randomize_LeftorRightSide_CheckForFollowers:

Randomize_LeftorRightSide_GetFirstPlayer:
    lwz r3, -0x3E74(r13)
    lwz r20, 0x0020(r3)
    b Randomize_LeftorRightSide_CheckIfPlayerExists

Randomize_LeftorRightSide_GetNextPlayer:
    lwz r20, 0x8(r20)

Randomize_LeftorRightSide_CheckIfPlayerExists:
    cmpwi r20, 0x0
    beq Randomize_LeftorRightSide_Exit
    lwz r21, 0x2C(r20)

    # Check If This Fighter is a Main Char
    lbz r3, 0x221F(r21)
    rlwinm. r0, r3, 29, 31, 31
    bne Randomize_LeftorRightSide_GetNextPlayer

    # Check For Follower, r20 = External. r21 = Internal
    mr r3, r20
    bl CheckIfPlayerHasAFollower
    cmpwi r3, 0x0                                       # No Follower, Go To Next Player
    beq Randomize_LeftorRightSide_GetNextPlayer

    # Transfer Info
    # Get Backups
    addi r3, r31, 0x10                                  # Get Backup Start
    lbz r4, 0xC(r21)                                    # Get Subchars Slot
    mulli r4, r4, 0x8                                   # Each Slot has 2 backups, so get to this slots backup
    add r3, r3, r4                                      # Each Slot has 2 backups, so get to this slots backup

    # Copy Main Char's Info Into Subchars
    lwz r4, 0x0(r3)                                     # Main Char Backup
    lwz r5, 0x4(r3)                                     # Follower Backup
    lwz r3, 0xB0(r4)                                    # Main Char X
    stw r3, 0xB0(r5)                                    # Into Subchar X
    lwz r3, 0x2C(r4)                                    # Main Char Facing
    stw r3, 0x2C(r5)                                    # Into Subchar Facing
    b Randomize_LeftorRightSide_GetNextPlayer

Randomize_LeftorRightSide_Exit:
    restore
    blr

# ********************************************#

Randomize_AlwaysPositive:
    fabs f1, f1                                         # Always Positive
    blr

Randomize_AlwaysNegative:
    fabs f1, f1
    fneg f1, f1                                         # Always Negative
    blr

# ********************************************#

############################################

IntToFloat:
    mflr r0
    stw r0, 0x4(r1)
    stwu r1, -0x100(r1)                                 # make space for 12 registers
    stmw r20, 0x8(r1)
    stfs f2, 0x38(r1)

    lis r0, 0x4330
    lfd f2, -0x6758(rtoc)
    xoris r3, r3, 0x8000
    stw r0, 0xF0(sp)
    stw r3, 0xF4(sp)
    lfd f1, 0xF0(sp)
    fsubs f1, f1, f2                                    # Convert To Float

    lfs f2, 0x38(r1)
    lmw r20, 0x8(r1)
    lwz r0, 0x104(r1)
    addi r1, r1, 0x100                                  # release the space
    mtlr r0
    blr

############################################

GetDirectionInRelationToP1:
    # Get P1 Direction
    lfs f1, 0xB0(r27)
    lfs f2, 0xB0(r29)
    fsubs f1, f1, f2
    lfs f2, -0x6768(rtoc)
    fcmpo cr0, f2, f1
    blt 0xC
    li r3, 1
    b 0x8
    li r3, -1
    blr

############################################

IsAnyoneDead:
    backup

IsAnyoneDead_GetFirstPlayer:
    lwz r3, -0x3E74(r13)
    lwz r20, 0x0020(r3)
    b IsAnyoneDead_CheckIfPlayerExists

IsAnyoneDead_GetNextPlayer:
    lwz r20, 0x8(r20)

IsAnyoneDead_CheckIfPlayerExists:
    cmpwi r20, 0x0
    bne IsAnyoneDead_GetPlayerData
    # Exit If No Other Players
    li r3, 0x0
    b IsAnyoneDead_Exit

IsAnyoneDead_GetPlayerData:
    lwz r21, 0x2C(r20)

    # Check If Follower
    lbz r3, 0x221F(r21)
    rlwinm. r0, r3, 0, 28, 28
    bne IsAnyoneDead_GetNextPlayer

    # Check If Dead
    lbz r3, 0x221F(r21)
    rlwinm. r0, r3, 0, 25, 25
    beq IsAnyoneDead_GetNextPlayer
    li r3, 0x1
    b IsAnyoneDead_Exit

IsAnyoneDead_Exit:
    restore
    blr

############################################

ResetStaleMoves:
    backup

ResetStaleMoves_GetFirstPlayer:
    lwz r3, -0x3E74(r13)
    lwz r20, 0x0020(r3)
    b ResetStaleMoves_CheckIfPlayerExists

ResetStaleMoves_GetNextPlayer:
    lwz r20, 0x8(r20)

ResetStaleMoves_CheckIfPlayerExists:
    cmpwi r20, 0x0
    bne ResetStaleMoves_GetPlayerData
    # Exit If No Other Players
    li r3, 0x0
    b ResetStaleMoves_Exit

ResetStaleMoves_GetPlayerData:
    lwz r21, 0x2C(r20)

    # Reset Stale Moves
    # Get Stale Move Table
    lbz r3, 0xC(r21)                                    # Get Slot
    branchl r12, 0x80036244                             # Get This Players Stale Table

    # Fill With 0's
    li r4, 0x2C
    branchl r12, ZeroAreaLength
    b ResetStaleMoves_GetNextPlayer

ResetStaleMoves_Exit:
    restore
    blr

############################################

MoveCPU:
# in
# r3 = P1 GObj
# r4 = P2 GObj
# r5 = SaveState Struct

    .set P1GObj, 31
    .set P1Data, 30
    .set P2GObj, 29
    .set P2Data, 28
    .set SaveStateStruct, 27
    .set P2Subchar, 26
    .set P2SubcharData, 25

    backup

    # Get Variables
    mr P1GObj, r3
    lwz P1Data, 0x2C(P1GObj)
    mr P2GObj, r4
    lwz P2Data, 0x2C(P2GObj)
    mr SaveStateStruct, r5

    # Get Input
    lbz r4, 0x0618(P1Data)
    load r3, InputStructStart
    mulli r0, r4, 68
    add r5, r0, r3

    # Check DPad Down
    lwz r3, 0xC(r5)
    rlwinm. r0, r3, 0, 29, 29
    beq MoveCPUExit
    # Make Sure Nothing Is Held
    lwz r3, 0x0(r5)
    li r4, 0
    rlwimi r3, r4, 0, 29, 29                            # except dpad down
    rlwimi r3, r4, 0, 27, 27                            # except Z (cause frame advance)
    cmpwi r3, 0
    bne MoveCPUExit

    # Make Sure Player is Grounded
    lwz r3, 0xE0(P1Data)
    cmpwi r3, 0x0
    bne MoveCPU_NoGroundFound

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
    beq MoveCPU_NoGroundFound
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

    # Check For Follower
    mr r3, P2GObj
    bl CheckIfPlayerHasAFollower
    cmpwi r3, 0
    beq MoveCPU_NoFollower
    mr P2Subchar, r3
    mr P2SubcharData, r4
    # Init Player Data Values (So CPU Init is called and nana knows where popp is)
    mr r3, P2Subchar
    branchl r12, 0x80068354
    # Copy Positions
    lfs f1, 0xB0(P2Data)
    stfs f1, 0xB0(P2SubcharData)
    lfs f1, 0xB4(P2Data)
    stfs f1, 0xB4(P2SubcharData)
    lwz r3, 0x83C(P2Data)
    stw r3, 0x83C(P2SubcharData)
    lfs f1, 0x2C(P2Data)
    stfs f1, 0x2C(P2SubcharData)
    # Enter Wait
    mr r3, P2Subchar
    branchl r12, AS_Wait
    # Update Position
    mr r3, P2Subchar
    bl UpdatePosition
    # Update ECB Values for the ground ID
    mr r3, P2Subchar
    branchl r12, EnvironmentCollision_WaitLanding
    # Set Grounded
    mr r3, P2SubcharData
    branchl r12, Air_SetAsGrounded

MoveCPU_NoFollower:
    # Savestate
    mr r3, SaveStateStruct
    li r4, 1                                            # Override failsafe code
    bl SaveState_Save
    # Play SFX
    li r3, 0xDD
    bl PlaySFX
    b MoveCPUExit

MoveCPU_NoGroundFound:
    # PLay Error SFX
    li r3, 0xAF
    bl PlaySFX

MoveCPUNoSubchar:

MoveCPUExit:
    restore
    blr

############################################

AdjustResetDistance:
    .set SaveStateStruct, 25
    .set P2Direction, 3
    .set PlayerX, 2
    .set P1X, 31
    .set P2X, 30

    backup

    mr SaveStateStruct, r3

    # Make Sure Nothing is Held
    lhz r3, 0x662(r27)
    rlwinm. r0, r3, 0, 27, 27
    bne 0xC
    cmpwi r3, 0x0
    bne AdjustResetDistance_NoPress

# Check For DPad Right
AdjustResetDistance_CheckRightDPad:
    lwz r3, 0x668(r27)                                  # Get DPad
    rlwinm. r0, r3, 0, 30, 30
    beq AdjustResetDistance_CheckLeftDPad
    # Move Apart
    # Determine if P2 is to the left or right of P1 + Get X Pos Multiplier
    bl GetDirectionInRelationToP1
    bl IntToFloat
    fmr P2Direction, f1
    # Load P1 Backup X Location
    lwz r20, 0x0(SaveStateStruct)
    lfs PlayerX, 0xB0(r20)
    # Add One in the correct direction
    li r3, 1
    bl IntToFloat
    fneg P2Direction, P2Direction
    fmuls f1, f1, P2Direction
    fadds P1X, f1, PlayerX                              # New P1 X
    # Load P2 Backup X Location
    lwz r21, 0x8(SaveStateStruct)
    lfs PlayerX, 0xB0(r21)
    # Add One in the correct direction
    li r3, 1
    bl IntToFloat
    fneg P2Direction, P2Direction
    fmuls f1, f1, P2Direction
    fadds P2X, f1, PlayerX                              # New P2 X
    # Store Back To PlayerBlock
    stfs P1X, 0xB0(r20)
    stfs P2X, 0xB0(r21)
    b AdjustResetDistance_WasPressed

# Check For DPad Left
AdjustResetDistance_CheckLeftDPad:
    rlwinm. r0, r3, 0, 31, 31
    beq AdjustResetDistance_NoPress
    # Move Together
    # Determine if P2 is to the left or right of P1 + Get X Pos Multiplier
    bl GetDirectionInRelationToP1
    bl IntToFloat
    fmr P2Direction, f1
    # Load P1 Backup X Location
    lwz r20, 0x0(SaveStateStruct)
    lfs PlayerX, 0xB0(r20)
    # Add One in the correct direction
    li r3, 1
    bl IntToFloat
    # fneg P2Direction, P2Direction
    fmuls f1, f1, P2Direction
    fadds P1X, f1, PlayerX                              # New P1 X
    # Load P2 Backup X Location
    lwz r21, 0x8(SaveStateStruct)
    lfs PlayerX, 0xB0(r21)
    # Add One in the correct direction
    li r3, 1
    bl IntToFloat
    fneg P2Direction, P2Direction
    fmuls f1, f1, P2Direction
    fadds P2X, f1, PlayerX                              # New P2 X
    # Check if already 10 Mm apart
    fsubs f2, P1X, P2X
    fabs f2, f2                                         # get abs distance from each other in f2
    li r3, 10
    bl IntToFloat
    fcmpo cr0, f2, f1
    ble AdjustResetDistance_NoPress
    # Store Back To PlayerBlock
    stfs P1X, 0xB0(r20)
    stfs P2X, 0xB0(r21)
    b AdjustResetDistance_WasPressed

AdjustResetDistance_NoPress:
    li r3, -1
    b AdjustResetDistance_Exit

AdjustResetDistance_WasPressed:
    li r3, 1

AdjustResetDistance_Exit:
    restore
    blr

############################################

CheckForActiveHitboxes:
    backup

    lwz r31, 0x2C(r3)

CheckForActiveHitboxes_InitLoop:
    li r29, 0x0

CheckForActiveHitboxes_LoopStart:
    lwz r0, 0x0914(r31)                                 # Check Hitbox Active Bool
    cmpwi r0, 0x0
    beq CheckForActiveHitboxes_NextHitbox
    li r3, 0x1
    b CheckForActiveHitboxes_Exit

CheckForActiveHitboxes_NextHitbox:
    addi r29, r29, 1
    addi r31, r31, 312                                  # Next Hitbox Struct
    cmpwi r29, 4
    blt CheckForActiveHitboxes_LoopStart

CheckForActiveHitboxes_NoHitboxesActive:
    li r3, 0x0

CheckForActiveHitboxes_Exit:
    restore
    blr

#############################################

Event_ExitFunction:
    blrl

    backup

    # Ensure No Contest/Retry
    lwz r3, MemcardData(r13)
    lbz r3, 0x053B(r3)
    rlwinm. r0, r3, 0, 25, 25
    bne Event_ExitFunction_Exit

    # Update Event Score
    load r20, 0x8045abf0                                # Current Event Info

    # Get High Score
    lbz r3, 0x5(r20)                                    # Event ID
    branchl r12, 0x8015cf5c
    mr r21, r3                                          # Backup High Score

    # Check If Event Was Played Yet
    lbz r3, 0x5(r20)                                    # Event ID
    branchl r12, 0x8015cefc
    cmpwi r3, 0x0
    beq Event_ExitFunction_SaveScore

    # Check If Greater
    lhz r3, -0x4ea6(r13)                                # Current Score
    cmpw r3, r21
    ble Event_ExitFunction_Exit

# Store As New High Score
Event_ExitFunction_SaveScore:
    lbz r3, 0x5(r20)                                    # Event ID
    lhz r4, -0x4ea6(r13)
    branchl r12, 0x8015cf70

    # Set Event As Played
    lbz r3, 0x5(r20)                                    # Event ID
    branchl r12, 0x8015ceb4

Event_ExitFunction_Exit:
    restore
    blr

#############################################

InitializeHighScore:
    backup

    # Create HUD KO Counter
    li r3, 0x0
    branchl r12, 0x802fa5bc

    # Init Score Count
    li r3, 0x0
    stw r3, -0x4ea8(r13)

    # Store Exit Function
    bl Event_ExitFunction
    mflr r3
    load r4, 0x8046b6a0
    stw r3, 0x2518(r4)

    restore
    blr

#############################################

PerformAerialThink:
# in
# r3 CPU Player Pointer
# r4 Pointer to dedicated memory to use
# r5 Attack to Perform (0 = Random, 1 = Fair, 2 = Nair, 3 = Dair)

    .set player, 31
    .set playerdata, 30
    .set variables, 29
    .set frame, 28
    .set aerialToPerform, 27
    .set performAerial, 0x00
    .set aerialAttack, 0x01
    .set attackFrame, 0x02

    backup

    # Get player pointers and frame count
    mr player, r3                                       # Get Player
    lwz playerdata, 0x2C(player)                        # Get Playerdata
    mr variables, r4                                    # Get Variable Memory
    lfs f1, 0x894(playerdata)                           # Get Frames as Int
    fctiwz f1, f1
    stfd f1, 0xF0(sp)
    lwz frame, 0xF4(sp)
    mr aerialToPerform, r5                              # Aerial to perform

    # Check To Aerial
    lbz r3, performAerial(variables)
    cmpwi r3, 0x0
    bne PerformAerialThink_Exit

    # Check Which Action to Perform
    lwz r3, 0x10(playerdata)                            # Get Action State

    # Branch To Think Functions
    # During Wait
    cmpwi r3, 0xE
    beq PerformAerialThink_DuringWait
    # During Jump
    cmpwi r3, 0x19
    beq PerformAerialThink_DuringJump
    cmpwi r3, 0x1A
    beq PerformAerialThink_DuringJump
    # During Attack
    cmpwi r3, 0x41
    blt 0x10
    cmpwi r3, 0x45
    bgt 0x8
    b PerformAerialThink_DuringAttack
    # During Landing
    cmpwi r3, 0x2A
    beq PerformAerialThink_DuringLanding
    cmpwi r3, 0x46
    blt 0x10
    cmpwi r3, 0x4A
    bgt 0x8
    b PerformAerialThink_DuringLanding
    # None of The Above
    b PerformAerialThink_Exit

PerformAerialThink_DuringWait:
    # Input Jump
    li r3, 0x800
    stw r3, 0x1A88(playerdata)
    # Determine Which Aerial Attack To Do
    # Check To Randomize
    cmpwi aerialToPerform, 0x0
    beq PerformAerialThink_GetRandomAttack
    # Store Attack Chosen
    subi r3, aerialToPerform, 0x1
    stb r3, aerialAttack(variables)
    b PerformAerialThink_CheckForValidAttack

PerformAerialThink_GetRandomAttack:
    li r3, 3
    branchl r12, HSD_Randi
    stb r3, aerialAttack(variables)

# Determine Frame to Attack on
PerformAerialThink_CheckForValidAttack:
    lwz r4, 0x4(playerdata)                             # get char ID
    bl PerformAerial_FrameData
    mflr r5
    mulli r4, r4, 0xC                                   # Get Characters Offset
    add r4, r4, r5                                      # Get Characters Table Entry Start
    mulli r3, r3, 0x2                                   # Move Frame Data is 0x2 Long
    add r27, r3, r4                                     # Get Moves Frame Data
    lbz r4, 0x0(r27)                                    # First Possible Frame
    lbz r5, 0x1(r27)                                    # Last Possible Frame
    cmpwi r4, 0x0
    bne PerformAerialThink_GetRandomFrame
    cmpwi r5, 0x0
    bne PerformAerialThink_GetRandomFrame
    # Move Disabled For Char, Get a New One
    b PerformAerialThink_GetRandomAttack

PerformAerialThink_GetRandomFrame:
    sub r3, r5, r4                                      # Get Amount of Possibilities
    branchl r12, HSD_Randi                              # Get Random Frame
    lbz r4, 0x0(r27)                                    # First Possible Frame
    add r3, r3, r4                                      # Adjust for First Possible Frame
    stb r3, attackFrame(variables)                      # Store Frame to Attack on
    b PerformAerialThink_Exit

PerformAerialThink_DuringJump:
    # Check To Attack
    lbz r3, attackFrame(variables)
    cmpw r3, frame
    bne PerformAerialThink_InputFastfallAndLCancel

    # Perform Attack
    lbz r3, aerialAttack(variables)                     # Get Attack ID
    cmpwi r3, 0x0
    beq PerformAerialThink_Fair
    cmpwi r3, 0x1
    beq PerformAerialThink_Nair
    cmpwi r3, 0x2
    beq PerformAerialThink_Dair

PerformAerialThink_Fair:
    li r3, 127                                          # Forward
    lfs f1, 0x2C(playerdata)                            # Facing Direction
    fctiwz f1, f1
    stfd f1, 0xF0(sp)
    lwz r4, 0xF4(sp)
    mullw r3, r3, r4                                    # Forward * facing direction
    stb r3, 0x1A8E(playerdata)
    b PerformAerialThink_InputFastfallAndLCancel

PerformAerialThink_Nair:
    li r3, 0x100
    stw r3, 0x1A88(playerdata)
    b PerformAerialThink_InputFastfallAndLCancel

PerformAerialThink_Dair:
    li r3, -127
    stb r3, 0x1A8F(playerdata)
    b PerformAerialThink_InputFastfallAndLCancel

    b PerformAerialThink_InputFastfallAndLCancel

PerformAerialThink_DuringAttack:
    b PerformAerialThink_InputFastfallAndLCancel

PerformAerialThink_DuringLanding:
    # Set Sequence as Over
    li r3, 1
    stb r3, performAerial(variables)
    b PerformAerialThink_Exit

PerformAerialThink_InputFastfallAndLCancel:
    # Input Fastfall
    # Check If Already FastFalling
    lbz r3, 0x221A(playerdata)
    rlwinm. r3, r3, 0, 28, 28
    bne PerformAerialThink_InputLCancel
    # Check If Falling
    lfs f2, 0x84(playerdata)
    lfs f0, -0x76B0(rtoc)
    fcmpo cr0, f2, f0
    bge PerformAerialThink_InputLCancel
    # Check If Inputting A Nair
    lwz r3, 0x1A88(playerdata)
    cmpwi r3, 0x100
    beq PerformAerialThink_InputLCancel
    # Input Down to FF
    li r3, -127
    stb r3, 0x1A8D(playerdata)                          # Analog Y

PerformAerialThink_InputLCancel:
    # Spoof Mash L
    li r3, 0x1
    stb r3, 0x67F(playerdata)

    b PerformAerialThink_Exit

#################################

PerformAerial_FrameData:
    blrl
    # Mario
    .long 0x00040012                                    # Fair and Nair
    .long 0x00100005                                    # Dar and UAir
    .long 0x0005FFFF                                    # Bair and Nothing

    # Fox
    .long 0x0009000A                                    # Fair and Nair
    .long 0x00080005                                    # Dar and UAir
    .long 0x0005FFFF                                    # Bair and Nothing

    # Cptn Falcon
    .long 0x0006000E                                    # Fair and Nair
    .long 0x00040005                                    # Dar and UAir
    .long 0x0005FFFF                                    # Bair and Nothing

    # DK
    .long 0x00050005                                    # Fair and Nair
    .long 0x00050005                                    # Dar and UAir
    .long 0x0005FFFF                                    # Bair and Nothing

    # Kirby
    .long 0x00050005                                    # Fair and Nair
    .long 0x00050005                                    # Dar and UAir
    .long 0x0005FFFF                                    # Bair and Nothing

    # Bowser
    .long 0x00050005                                    # Fair and Nair
    .long 0x00050005                                    # Dar and UAir
    .long 0x0005FFFF                                    # Bair and Nothing

    # link
    .long 0x00050005                                    # Fair and Nair
    .long 0x00050005                                    # Dar and UAir
    .long 0x0005FFFF                                    # Bair and Nothing

    # Sheik
    .long 0x10140018                                    # Fair and Nair
    .long 0x00000005                                    # Dar (was 0-A) and UAir
    .long 0x0005FFFF                                    # Bair and Nothing

    # Ness
    .long 0x00050005                                    # Fair and Nair
    .long 0x00050005                                    # Dar and UAir
    .long 0x0005FFFF                                    # Bair and Nothing

    # Peach
    .long 0x000D001A                                    # Fair and Nair
    .long 0x000E0005                                    # Dar and UAir
    .long 0x0005FFFF                                    # Bair and Nothing

    # Popo
    .long 0x00050005                                    # Fair and Nair
    .long 0x00050005                                    # Dar and UAir
    .long 0x0005FFFF                                    # Bair and Nothing

    # Nana
    .long 0x00050005                                    # Fair and Nair
    .long 0x00050005                                    # Dar and UAir
    .long 0x0005FFFF                                    # Bair and Nothing

    # Pikachu
    .long 0x000C000F                                    # Fair and Nair
    .long 0x00080005                                    # Dar and UAir
    .long 0x0005FFFF                                    # Bair and Nothing

    # Samus
    .long 0x00200020                                    # Fair and Nair
    .long 0x080D0005                                    # Dar and UAir
    .long 0x0005FFFF                                    # Bair and Nothing

    # Yoshi
    .long 0x00050005                                    # Fair and Nair
    .long 0x00050005                                    # Dar and UAir
    .long 0x0005FFFF                                    # Bair and Nothing

    # Jiggs
    .long 0x00100010                                    # Fair and Nair
    .long 0x00100005                                    # Dar and UAir
    .long 0x0005FFFF                                    # Bair and Nothing

    # mewtwo
    .long 0x00050019                                    # Fair and Nair
    .long 0x00050005                                    # Dar and UAir
    .long 0x0005FFFF                                    # Bair and Nothing

    # Luigi
    .long 0x0017001B                                    # Fair and Nair
    .long 0x00110005                                    # Dar and UAir
    .long 0x0005FFFF                                    # Bair and Nothing

    # Marth
    .long 0x00160013                                    # Fair and Nair
    .long 0x00120005                                    # Dar and UAir
    .long 0x0005FFFF                                    # Bair and Nothing

    # Zelda
    .long 0x00050005                                    # Fair and Nair
    .long 0x00050005                                    # Dar and UAir
    .long 0x0005FFFF                                    # Bair and Nothing

    # YLink
    .long 0x00050005                                    # Fair and Nair
    .long 0x00050005                                    # Dar and UAir
    .long 0x0005FFFF                                    # Bair and Nothing

    # Doc
    .long 0x00050005                                    # Fair and Nair
    .long 0x00050005                                    # Dar and UAir
    .long 0x0005FFFF                                    # Bair and Nothing

    # Falco
    .long 0x070B000D                                    # Fair and Nair
    .long 0x000C0005                                    # Dar and UAir
    .long 0x0005FFFF                                    # Bair and Nothing

    # Pichu
    .long 0x00050005                                    # Fair and Nair
    .long 0x00050005                                    # Dar and UAir
    .long 0x0005FFFF                                    # Bair and Nothing

    # GaW
    .long 0x00050005                                    # Fair and Nair
    .long 0x00050005                                    # Dar and UAir
    .long 0x0005FFFF                                    # Bair and Nothing

    # Ganon
    .long 0x00050005                                    # Fair and Nair
    .long 0x00050005                                    # Dar and UAir
    .long 0x0005FFFF                                    # Bair and Nothing

    # Roy
    .long 0x00050005                                    # Fair and Nair
    .long 0x00050005                                    # Dar and UAir
    .long 0x0005FFFF                                    # Bair and Nothing

####################################

PerformAerialThink_Exit:
    restore
    blr

#####################################
RandFloat:
# in
# r3 = Rand Float Lower Bound
# r4 = Rand Float Upper Bound

    backup
    stfs f31, 0x80(sp)

    mr r31, r3

    # Get Random Upper Bound
    sub r3, r4, r31
    branchl r12, HSD_Randi
    # Add Lower Bound
    add r3, r3, r31
    # Convert to Float
    bl IntToFloat
    fmr f31, f1
    # Get Random Float
    branchl r12, HSD_Randf
    fadds f1, f1, f31

    lfs f31, 0x80(sp)
    restore
    blr

#####################################
Custom_InterruptRebirthWait:
    blrl
    .set player, 31
    .set playdata, 30

    backup

    # Get Pointers
    mr player, r3
    lwz playerdata, 0x2C(player)

    # Check For Aerial Jump
    mr r3, player
    branchl r12, 0x800cb870
    cmpwi r3, 0x0
    bne Custom_InterruptRebirthWait_Exit

    # Ensure Stick Was Just Moved
    lbz r3, 0x0670(playerdata)
    cmpwi r3, 2
    bge Custom_InterruptRebirthWait_CheckJoystickDown
    # Check For Any X Joystick Push
    lwz r3, -0x514C(r13)
    lfs f0, 0x0024(r3)
    lfs f1, 0x0620(playerdata)
    fabs f1, f1
    fcmpo cr0, f1, f0
    cror 2, 1, 2
    beq Custom_InterruptRebirthWait_EnterFall

Custom_InterruptRebirthWait_CheckJoystickDown:
    # Ensure Stick Was Just Moved
    lbz r3, 0x0671(playerdata)
    cmpwi r3, 4
    bge Custom_InterruptRebirthWait_Exit
    # Check For Down Joystick Push
    lwz r3, -0x514C(r13)
    lfs f0, 0x0090(r3)
    fneg f0, f0
    lfs f1, 0x0624(playerdata)
    fcmpo cr0, f1, f0
    blt Custom_InterruptRebirthWait_EnterFall
    b Custom_InterruptRebirthWait_Exit

Custom_InterruptRebirthWait_EnterFall:
    # Enter Fall
    mr r3, player
    branchl r12, AS_Fall

Custom_InterruptRebirthWait_Exit:
    restore
    blr

#####################################
UpdatePosition:
    .set PlayerGObj, 31
    .set PlayerData, 30

    backup

    # Backup Pointer
    mr PlayerGObj, r3
    lwz PlayerData, 0x2C(PlayerGObj)

    # Update Position (Copy Physics XYZ into all ECB XYZ)
    # X
    lwz r3, 0x00B0(PlayerData)
    stw r3, 0x06F4(PlayerData)
    stw r3, 0x0700(PlayerData)
    stw r3, 0x070C(PlayerData)
    stw r3, 0x0718(PlayerData)
    # Y
    lwz r3, 0x00B4(PlayerData)
    stw r3, 0x06F8(PlayerData)
    stw r3, 0x0704(PlayerData)
    stw r3, 0x0710(PlayerData)
    stw r3, 0x071C(PlayerData)
    # Z
    lwz r3, 0x00B8(PlayerData)
    stw r3, 0x06FC(PlayerData)
    stw r3, 0x0708(PlayerData)
    stw r3, 0x0714(PlayerData)
    stw r3, 0x0720(PlayerData)
    # Update Collision Frame ID
    lwz r3, -0x51F4(r13)
    stw r3, 0x728(PlayerData)

# branchl r12, 0x80081b38 #Stopped using this because it deletes way too much ECB info
# branchl r12, 0x80082a68 #Better than the above function, but all i need is to copy current position into the ECB previous values

    # Adjust JObj position (code copied from 8006c324)
    lwz r3, 0x28(PlayerGObj)                            # get character model JObj
    lwz r4, 0xB0(PlayerData)                            # get X
    stw r4, 0x38(r3)                                    # store X
    lwz r4, 0xB4(PlayerData)                            # get Y
    stw r4, 0x3C(r3)                                    # store Y
    lwz r4, 0xB8(PlayerData)                            # get Z
    stw r4, 0x40(r3)                                    # store Z
# Dirty Sub
# branchl r12, 0x803732e8

    # Update Static Player Block Coords
    lbz r3, 0xC(PlayerData)
    lbz r4, 0x221F(PlayerData)
    rlwinm r4, r4, 29, 31, 31
    addi r5, PlayerData, 176
    branchl r12, 0x80032828

    restore
    blr

#####################################

GetGroundCenter:
# in
# r3 = Ground ID

    # Get Corner IDs from Ground ID
    mulli r0, r3, 8
    lwz r5, -0x51E4(r13)
    lwzx r5, r5, r0
    lhz r3, 0x0(r5)
    lhz r4, 0x2(r5)

    # Get Coordinates
    lwz r5, -0x51E8(r13)
    mulli r3, r3, 24
    addi r3, r3, 8
    add r3, r3, r5
    lfs f1, 0x0(r3)                                     # Left X
    lfs f2, 0x4(r3)                                     # Left Y
    mulli r4, r4, 24
    addi r4, r4, 8
    add r4, r4, r5
    lfs f3, 0x0(r4)                                     # Right X
    lfs f4, 0x4(r4)                                     # Right Y

    # Get Center Value
    lfs f5, -0x4df0(rtoc)                               # 2f
    fadds f1, f1, f3
    fdivs f1, f1, f5                                    # Center X
    fadds f2, f2, f4
    fdivs f2, f2, f5                                    # Center Y

    blr

####################################

PlacePlayersCenterStage:
# in
# r3 - ground id

    backup

    # Loop through players 1 and 2
    .set count, 27
    .set player, 26
    .set playerdata, 25
    .set subchar, 24
    .set subchardata, 23
    .set ground_id, 22

    li count, 0
    mr ground_id, r3

PlacePlayersCenterStage_Loop:
    # Get Player GObj
    mr r3, r27
    branchl r12, PlayerBlock_LoadMainCharDataOffset
    # Check if exists
    cmpwi r3, 0x0
    beq PlacePlayersCenterStage_IncLoop
    mr player, r3
    lwz playerdata, 0x2C(player)
    # Get Subchar Bool
    bl CheckIfPlayerHasAFollower
    mr subchar, r3
    mr subchardata, r4
    # Call function to do heavy lifting
    mr r3, player
    bl PlacePlayersCenterStage_DoStuff
    # Check if subchar exits
    cmpwi subchar, 0
    beq PlacePlayersCenterStage_IncLoop
    # Call function for this character
    mr r3, subchar
    bl PlacePlayersCenterStage_DoStuff

# Next Player
PlacePlayersCenterStage_IncLoop:
    addi count, count, 1
    cmpwi count, 6
    blt PlacePlayersCenterStage_Loop
    b PlacePlayersCenterStage_Exit

# *****************************#
PlacePlayersCenterStage_DoStuff:
# in
# r3 = player

    .set player, 31
    .set playerdata, 30
    .set constants, 29

    backup

    # Get Pointers
    mr player, r3
    lwz playerdata, 0x2C(r3)

    # Get Constants
    bl PlacePlayersCenterStage_Constants
    mflr constants
    lbz r3, 0xC(playerdata)
    mulli r3, r3, 0x2
    add constants, constants, r3

    # Initialize Player Data (Mainly for ICs so Nana knows where Popo is)
    mr r3, player
    branchl r12, 0x80068354

    mr r3, ground_id
    bl GetGroundCenter
    fmr f30, f1
    fmr f31, f2

    # Facing Directions
    lbz r3, 0x0(constants)                              # This players facing direction
    extsb r3, r3
    bl IntToFloat
    stfs f1, 0x2C(playerdata)

    # Move Players
    lbz r3, 0x1(constants)                              # This players X offset
    extsb r3, r3
    bl IntToFloat
    fadds f2, f1, f30                                   # Player X = X+6
    stfs f2, 0xB0(playerdata)
    stfs f31, 0xB4(playerdata)

    # Enter into Wait
    mr r3, player
    branchl r12, AS_Wait
    # Find Ground Below Player
    mr r3, player
    bl FindGroundNearPlayer
    cmpwi r3, 0                                         # Check if ground was found
    beq PlacePlayersCenterStage_DoStuff_SkipGroundCorrection
    stfs f1, 0xB0(playerdata)
    stfs f2, 0xB4(playerdata)
    stw r4, 0x83C(playerdata)

PlacePlayersCenterStage_DoStuff_SkipGroundCorrection:
    # Update Position
    mr r3, player
    bl UpdatePosition
    # Update ECB Values for the ground ID
    mr r3, player
    branchl r12, EnvironmentCollision_WaitLanding
    # Set Grounded
    mr r3, playerdata
    branchl r12, Air_SetAsGrounded
    # Update Camera
    mr r3, player
    bl UpdateCameraBox

PlacePlayersCenterStage_DoStuff_Exit:
    restore
    blr

# *********#

PlacePlayersCenterStage_Constants:
    blrl
    .byte 1, -6, -1, 6
    .align 2

# *********#

PlacePlayersCenterStage_Exit:
    restore
    blr

#####################################

FindGroundNearPlayer:
# in
# r3 = player GObj (optional)
# f1 = X value
# f2 = Y Value

    .set player, 31
    .set playerdata, 30

    backup
    stfs f30, 0x38(sp)
    stfs f31, 0x3C(sp)

    # Check If Given Player GObj
    cmpwi r3, 0x0
    bne FindGroundNearPlayer_GObjPassedIn

FindGroundNearPlayer_CoordinatesPassedIn:
    # Backup Coords
    fmr f30, f1
    fmr f31, f2
    # Get 10f
    li r3, 10
    bl IntToFloat
    # Get Bottom Coord
    fmr f3, f30                                         # Bottom X is same as Top X
    fsubs f4, f31, f1                                   # Bottom Y is Top Y - 1000
    # Move Top Coords Back
    fmr f1, f30
    fmr f2, f31
    lfs f0, -0x7188(rtoc)
    fadds f2, f2, f0
    b FindGroundNearPlayer_Continue

FindGroundNearPlayer_GObjPassedIn:
    # Init Variables
    mr player, r3
    lwz playerdata, 0x2C(player)
    # Get Players X and Y+10
    lfs f1, 0xB0(playerdata)
    lfs f2, 0xB4(playerdata)
    lfs f0, -0x7188(rtoc)
    fadds f2, f2, f0
    # Get Bottom Coord (X and Y-1000)
    lfs f3, 0xB0(playerdata)
    lfs f4, 0xB0(playerdata)
    lfs f0, -0x71A8(rtoc)
    fsubs f4, f4, f0

FindGroundNearPlayer_Continue:
    # Get Unk f5 argument
    lfs f5, -0x7208(rtoc)
    # Setup stack for return values
    addi r3, sp, 0x54                                   # (Returns Ground Coordinates
    addi r4, sp, 0x44                                   # (Returns Ground ID)
    addi r5, sp, 0x40                                   # (Returns Ground Type)
    addi r6, sp, 0x48                                   # (Returns Unk)
    # Unk arguments
    li r7, -1
    li r8, -1
    li r9, -1
    # Additional function pointer
    li r10, 0
    # Call function
    branchl r12, Raycast_GroundLine

    # Check if ground exists
    cmpwi r3, 0
    beq FindGroundNearPlayer_Exit

    # Return Coordinates of ground below player
    lfs f1, 0x54(sp)
    lfs f2, 0x58(sp)
    lwz r4, 0x44(sp)

FindGroundNearPlayer_Exit:
    lfs f30, 0x38(sp)
    lfs f31, 0x3C(sp)
    restore
    blr

#####################################

FindGroundUnderCoordinate:
# in
# f1 = X value
# f2 = Y Value

    backup
    stfs f30, 0x38(sp)
    stfs f31, 0x3C(sp)

FindGroundUnderCoordinate_CoordinatesPassedIn:
    # Backup Coords
    fmr f30, f1
    fmr f31, f2
    # Get 1000f
    li r3, 1000
    bl IntToFloat
    # Get Bottom Coord
    fmr f3, f30                                         # Bottom X is same as Top X
    fsubs f4, f31, f1                                   # Bottom Y is Top Y - 1000
    # Move Top Coords Back
    fmr f1, f30
    fmr f2, f31

FindGroundUnderCoordinate_Continue:
    # Get Unk f5 argument
    lfs f5, -0x7208(rtoc)
    # Setup stack for return values
    addi r3, sp, 0x54                                   # (Returns Ground Coordinates
    addi r4, sp, 0x44                                   # (Returns Ground ID)
    addi r5, sp, 0x40                                   # (Returns Ground Type)
    addi r6, sp, 0x48                                   # (Returns Unk)
    # Unk arguments
    li r7, -1
    li r8, -1
    li r9, -1
    li r10, 0
    # Call function
    branchl r12, Raycast_GroundLine

    # Check if ground exists
    cmpwi r3, 0
    beq FindGroundUnderCoordinate_Exit

    # Return Coordinates of ground below player
    lfs f1, 0x54(sp)
    lfs f2, 0x58(sp)
    lwz r4, 0x44(sp)

FindGroundUnderCoordinate_Exit:
    lfs f30, 0x38(sp)
    lfs f31, 0x3C(sp)
    restore
    blr

#####################################
PlacePlayerOnGround:
    backup

    .set REG_GObj, 31
    .set REG_GObjData, 30

    # Get Pointers
    mr REG_GObj, r3
    lwz REG_GObjData, 0x2C(REG_GObj)

    # Find Ground Below Player
    mr r3, REG_GObj
    bl FindGroundNearPlayer
    cmpwi r3, 0                                         # Check if ground was found
    beq PlacePlayerOnGround_SkipGroundCorrection
    stfs f1, 0xB0(REG_GObjData)
    stfs f2, 0xB4(REG_GObjData)
    stw r4, 0x83C(REG_GObjData)

PlacePlayerOnGround_SkipGroundCorrection:
    # Update Position
    mr r3, REG_GObj
    bl UpdatePosition
    # Update ECB Values for the ground ID
    mr r3, REG_GObj
    branchl r12, EnvironmentCollision_WaitLanding
    # Set Grounded
    mr r3, REG_GObjData
    branchl r12, Air_SetAsGrounded

PlacePlayerOnGround_Exit:
    restore
    blr

#####################################
PlaySFX:
    backup

    branchl r12, SFX_PlaySoundAtFullVolume

    restore
    blr

#####################################

UpdateCameraBox:
# in
# r3 = player

    .set player, 31
    .set playerdata, 30

    backup

    # Get Pointer
    mr player, r3
    lwz playerdata, 0x2C(player)

    # Update Camera Box Position
    mr r3, player
    branchl r12, Camera_UpdatePlayerCameraBoxPosition

# Update Camera Box Direction Tween
# lwz r3, 0x2C(player)
# branchl r12, 0x80076064

    # Update Camera Box Direction Tween
    lwz r3, 0x890(playerdata)
    lfs f1, 0x40(r3)                                    # Leftmost Bound
    stfs f1, 0x2C(r3)                                   # Current Left Box Bound
    lfs f1, 0x44(r3)                                    # Rightmost Bound
    stfs f1, 0x30(r3)                                   # Current Right Box Bound

    # Correct Camera Position
    branchl r12, Camera_CorrectPosition

    restore
    blr

#####################################

GetAllPlayerPointers:
# in
# nothing

# out
# r3 = P1GObj
# r4 = P1Data
# r5 = P2GObj
# r6 = P2Data
# r7 = P3GObj
# r8 = P3Data
# r9 = P4GObj
# r10 = P4Data

    backup

    # Get Space to Store all Pointer to
    addi r21, sp, 0x40
    # Init Loop Count
    li r20, 0

GetAllPlayerPointers_Loop:
    # Get GObj
    mr r3, r20
    branchl r12, PlayerBlock_LoadMainCharDataOffset
    # Check If Exists
    cmpwi r3, 0x0
    li r4, 0                                            # Zero Data pointer just in case it doesnt exist
    beq GetAllPlayerPointers_StoreToStack
    # Get Data
    lwz r4, 0x2C(r3)

# Store Both to Stack
GetAllPlayerPointers_StoreToStack:
    mulli r5, r20, 8
    add r5, r5, r21
    stw r3, 0x0(r5)
    stw r4, 0x4(r5)

GetAllPlayerPointers_IncLoop:
    addi r20, r20, 1
    cmpwi r20, 4
    blt GetAllPlayerPointers_Loop

GetAllPlayerPointers_LoadPointers:
    lwz r3, 0x00(r21)
    lwz r4, 0x04(r21)
    lwz r5, 0x08(r21)
    lwz r6, 0x0C(r21)
    lwz r7, 0x10(r21)
    lwz r8, 0x14(r21)
    lwz r9, 0x18(r21)
    lwz r10, 0x1C(r21)

GetAllPlayerPointers_Exit:
    restore
    blr

#####################################
RemoveFirstFrameInputs:
RemoveFirstFrameInputs_GetFirstPlayer:
    lwz r3, -0x3E74(r13)
    lwz r12, 0x0020(r3)
    b RemoveFirstFrameInputs_CheckIfPlayerExists

RemoveFirstFrameInputs_GetNextPlayer:
    lwz r12, 0x8(r12)

RemoveFirstFrameInputs_CheckIfPlayerExists:
    cmpwi r12, 0x0
    beq RemoveFirstFrameInputs_Exit
    lwz r5, 0x2C(r12)

    # Remove Input Flag
    lbz r0, 0x221D(r5)
    li r3, 0x1
    rlwimi r0, r3, 4, 27, 27
    stb r0, 0x221D(r5)
    # Store Current Input
    lbz r4, 0x0618(r5)
    load r3, InputStructStart
    mulli r0, r4, 68
    add r3, r0, r3
    lwz r0, 0(r3)
    stw r0, 0x065C(r5)
    b RemoveFirstFrameInputs_GetNextPlayer

RemoveFirstFrameInputs_Exit:
    blr

#####################################

InitializeMatch:
    .set REG_EventStruct, 31
    .set REG_MatchStruct, 30
    .set REG_CPUChoice, 29
    .set REG_StageChoice, 28
    .set REG_EventOSDs, 27
    .set REG_PlayerStruct, 26
    .set REG_UseSopo, 25

    # Init
    backup
    mr REG_EventStruct, r3
    mr REG_MatchStruct, r4
    mr REG_CPUChoice, r5
    mr REG_StageChoice, r6
    mr REG_EventOSDs, r7
    mr REG_UseSopo, r8

    # Check to override OSD Toggles
    lwz r4, MemcardData(r13)
    lbz r3, 0x1f2A(r4)
    cmpwi r3, 1
    beq InitializeMatch_SkipOSDOverride
    # Store Events FDD Toggles
    lwz r3, 0x1F24(r4)
    or r3, r3, REG_EventOSDs
    stw r3, 0x1F24(r4)

InitializeMatch_SkipOSDOverride:
    # SPAWN 2 PLAYERS
    li r3, 0x40
    stb r3, 0x1(REG_EventStruct)

    # Make Copy of Struct
    li r3, 32
    branchl r12, HSD_MemAlloc
    mr REG_PlayerStruct, r3
    bl P2Struct
    mflr r4
    li r5, 0x1C
    branchl r12, memcpy
    # Store to P2 pointer in event struct
    stw REG_PlayerStruct, 0x18(REG_EventStruct)

    # Store CPU
    cmpwi REG_CPUChoice, -1
    beq InitializeMatch_StoreCSSCPU
    # Store this CPU
    stb REG_CPUChoice, 0x0(REG_PlayerStruct)
    b InitializeMatch_StoreStage

InitializeMatch_StoreCSSCPU:
    load r3, 0x8043207c                                 # get preload table
    lwz r4, 0x18(r3)                                    # get p2 character ID
    cmpwi r4, 0x12                                      # check if zelda
    bne 0x8
    li r4, 0x13                                         # make zelda sheik
    stb r4, 0x0(REG_PlayerStruct)                       # store chosen char
    lbz r6, 0x1C(r3)                                    # get p2 costume ID
    stb r6, 0x3(REG_PlayerStruct)                       # store p2 costume ID
    li r5, 0x1                                          # make CPU controlled
    stb r5, 0x1(REG_PlayerStruct)

InitializeMatch_StoreStage:
    # Store Stage
    cmpwi REG_StageChoice, -1
    beq InitializeMatch_StoreSSSStage
    # Store this Stage
    sth REG_StageChoice, 0xE(REG_MatchStruct)
    b InitializeMatch_StoreStage_End

InitializeMatch_StoreSSSStage:
    load r3, 0x8043207c                                 # get preload table
    lwz r3, 0x00C(r3)
    sth r3, 0xE(REG_MatchStruct)                        # store chosen stage

InitializeMatch_StoreStage_End:
InitializeMatch_SwapInSopo:
    cmpwi REG_UseSopo, 0
    beq InitializeMatch_SwapInSopo_End
    # Swap P1 Character to Sopo
    lwz r4, MemcardData(r13)
    addi r4, r4, 1328                                   # event mode match backup struct?
    lbz r3, 0x2(r4)                                     # P1 External ID
    cmpwi r3, 0xE
    bne InitializeMatch_SwapInSopo_End
    li r3, 0x20
    stb r3, 0x2(r4)                                     # Make SoPo

InitializeMatch_SwapInSopo_End:
InitializeMatch_Exit:
    restore
    blr

#####################################

GetDistance:
    lfs f3, 0x0(r3)                                     # X
    lfs f4, 0x4(r3)                                     # Y
    lfs f5, 0x0(r4)                                     # X
    lfs f6, 0x4(r4)                                     # Y
    fsubs f1, f5, f3
    fsubs f2, f4, f6
    fmuls f1, f1, f1
    fmuls f2, f2, f2
    fadds f2, f1, f2
    frsqrte f1, f2
    fmuls f1, f1, f2
    blr

#####################################

GetLedgeCoordinates:
    .set LedgeSide, 20
    .set LedgeID, 21
    .set Return, 22

    backup

    # Backup Ledge Choice (0 = Left, 1 = Right)
    mr LedgeSide, r3
    mr Return, r4

    # Get Stage's Ledge IDs
    lwz r3, -0x6CB8(r13)                                # External Stage ID
    bl LedgeCliffIDs
    mflr r4
    mulli r3, r3, 0x2
    lhzx r3, r3, r4
    # Get Requested Ledge
    cmpwi LedgeSide, 0x0
    beq GetLedgeCoordinates_GetLeftLedgeID

GetLedgeCoordinates_GetRightLedgeID:
    rlwinm LedgeID, r3, 0, 24, 31
    # Get Ledge Coords (0x80 = X, 0x84 = Y)
    mr r3, LedgeID
    mr r4, Return
    branchl r12, Stage_GetRightOfLineCoordinates
    b GetLedgeCoordinates_Exit

GetLedgeCoordinates_GetLeftLedgeID:
    rlwinm LedgeID, r3, 24, 24, 31
    # Get Ledge Coords (0x80 = X, 0x84 = Y)
    mr r3, LedgeID
    mr r4, Return
    branchl r12, Stage_GetLeftOfLineCoordinates
    b GetLedgeCoordinates_Exit

GetLedgeCoordinates_Exit:
    restore
    blr

##########################################
GetAngleBetweenPoints:
    .set REG_arctan, 2
    .set REG_Constants, 31

    backup

    # Get Constants
    bl GetAngleBetweenPoints_Constants
    mflr REG_Constants

    # Get Values
    lfs f1, 0x0(r3)
    lfs f2, 0x4(r3)
    lfs f3, 0x0(r4)
    lfs f4, 0x4(r4)
    # Get slope ydelta / xdelta
    fsubs f5, f4, f2
    fsubs f6, f3, f1
    fdivs f1, f5, f6
    # atan
    branchl r12, 0x80022e68
    fmr REG_arctan, f1

# Ensure above 0 and below 6.28319
GetAngleBetweenPoints_CheckIfOver0:
    lfs f1, 0x0(REG_Constants)
    fcmpo cr0, REG_arctan, f1
    bge GetAngleBetweenPoints_CheckIfUnder360
    # Add 180
    lfs f1, 0x8(REG_Constants)
    fadds REG_arctan, REG_arctan, f1
    b GetAngleBetweenPoints_CheckIfOver0

GetAngleBetweenPoints_CheckIfUnder360:
    lfs f1, 0x4(REG_Constants)
    fcmpo cr0, REG_arctan, f1
    ble GetAngleBetweenPoints_Under360
    # Add 180
    lfs f1, 0x8(REG_Constants)
    fsubs REG_arctan, REG_arctan, f1
    b GetAngleBetweenPoints_CheckIfUnder360

GetAngleBetweenPoints_Under360:
    fmr f1, REG_arctan

GetAngleBetweenPoints_Exit:
    restore
    blr

GetAngleBetweenPoints_Constants:
    blrl
    .float 0
    .float 6.28319
    .float 3.14159

##########################################
EnterKnockback:
    backup

    .set REG_GObj, 31
    .set REG_GObjData, 30
    .set REG_AngleLo, 29
    .set REG_AngleHi, 28
    .set REG_MagLo, 27
    .set REG_MagHi, 26
    .set REG_Angle, 29
    .set REG_Magnitude, 28

    # Backup Data
    mr REG_GObj, r3
    lwz REG_GObjData, 0x2C(REG_GObj)
    mr REG_AngleLo, r4
    mr REG_AngleHi, r5
    mr REG_MagLo, r6
    mr REG_MagHi, r7

    # Random angle between
    sub r3, REG_AngleHi, REG_AngleLo
    branchl r12, HSD_Randi
    add REG_Angle, r3, REG_AngleLo
    # Cast to float
    mr r3, REG_Angle
    bl IntToFloat
    # Now in radians
    lfs f2, -0x7510(rtoc)
    fmuls f1, f1, f2
    stfs f1, 0x80(sp)

    # Random magnitude between X and Y
    mr r3, REG_MagLo
    mr r4, REG_MagHi
    bl RandFloat
    stfs f1, 0x7C(sp)                                   # will be used later for
    lwz r3, -0x514C(r13)
    lfs f0, 0x0100(r3)
    fmuls f1, f1, f0
    stfs f1, 0x84(sp)

    # Get X Component
    lfs f1, 0x80(sp)                                    # KB angle in radians
    branchl r12, cos
    lfs f2, 0x84(sp)                                    # KB magnitude
    fmuls f1, f1, f2
    lfs f2, 0x2C(REG_GObjData)
    fneg f2, f2
    fmuls f1, f1, f2
    stfs f1, 0x8C(REG_GObjData)
    # Get Y Component
    lfs f1, 0x80(sp)                                    # KB angle in radians
    branchl r12, sin
    lfs f2, 0x84(sp)                                    # KB magnitude
    fmuls f1, f1, f2
    stfs f1, 0x90(REG_GObjData)

    # Calculate Hitstun
    lwz r3, -0x514C(r13)
    lfs f0, 0x0154(r3)
    lfs f1, 0x7C(sp)
    fmuls f1, f1, f0                                    # hitstun frames is 0.4 * magnitude
    fctiwz f1, f1                                       # Round down
    stfd f1, 0x88(sp)
    lwz r3, 0x8C(sp)
    bl IntToFloat
    stfs f1, 0x2340(REG_GObjData)
    # Enable Hitstun Bit
    lbz r0, 0x221C(REG_GObjData)
    li r3, 1
    rlwimi r0, r3, 1, 30, 30
    stb r0, 0x221C(REG_GObjData)

    # Enable ECB Update
    mr r3, REG_GObjData
    branchl r12, 0x8007d5bc

EnterKnockback_Exit:
    restore
    blr

##########################################
DisableHazards:
    # Get list start
    bl DisableHazards_SkipList
    ########################
    bl DisableHazards_Dummy
    bl DisableHazards_TEST
    bl DisableHazards_Izumi
    bl DisableHazards_Pstadium
    bl DisableHazards_Castle
    bl DisableHazards_Kongo
    bl DisableHazards_Zebes
    bl DisableHazards_Corneria
    bl DisableHazards_Story
    bl DisableHazards_Onett
    bl DisableHazards_MuteCity
    bl DisableHazards_RCruise
    bl DisableHazards_Garden
    bl DisableHazards_GreatBay
    bl DisableHazards_Shrine
    bl DisableHazards_Kraid
    bl DisableHazards_Yoster
    bl DisableHazards_Greens
    bl DisableHazards_Fourside
    bl DisableHazards_MK1
    bl DisableHazards_MK2
    bl DisableHazards_Akaneia
    bl DisableHazards_Venom
    bl DisableHazards_Pura
    bl DisableHazards_BigBlue
    bl DisableHazards_Icemt
    bl DisableHazards_Icetop
    bl DisableHazards_FlatZone
    bl DisableHazards_OldDL
    bl DisableHazards_OldYS
    bl DisableHazards_OldKongo
    bl DisableHazards_Battlefield
    bl DisableHazards_FinalDestination

########################
DisableHazards_SkipList:
    mflr r3
    lwz r4, StageID_External(r13)
    mulli r4, r4, 4
    add r4, r3, r4
    lwz r5, 0x0(r4)                                     # Get bl Instruction
    rlwinm r5, r5, 0, 6, 29                             # Mask Bits 6-29(the offset)
    cmpwi r5, 0                                         # If pointer is null, exit
    beq DisableHazards_SkipList_Exit
    add r4, r4, r5                                      # Pointer to code now in r4
    mtctr r4
    bctr

########################

DisableHazards_Story:
    /*
    # Get randall's line ID
    mr r3, REG_map_gobj
    branchl r12, 0x801c6330
    lwz r3, 0x4(r3)                                     # get map_head
    lwz r3, 0x8(r3)                                     # get map_gobj info
    mulli r4, REG_map_gobj, 52                          # get randall's info
    add r3, r3, r4
    lwz r3, 0x20(r3)                                    # pointer to the collision data
    lhz r3, 0x0(r3)                                     # i believe this is randalls line ID
    # Get randalls corner IDs
    mulli r3, r3, 8                                     # 0x8 in length
    lwz r4, -0x51E4(r13)                                # line to corner ID table
    lwzx r5, r3, r4                                     # now have the corner ID struct
    lhz r3, 0x0(r5)                                     # left corner id
    lhz r4, 0x2(r5)                                     # right corner id
    # Get corner IDs info
    lwz r5, -0x51E8(r13)
    mulli r3, r3, 24
    mulli r4, r4, 24
    add r3, r3, r5
    add r4, r4, r5
    # Zero current X and Y positions, effectively removing these lines
    li r5, 0
    stw r5, 0x8(r3)
    stw r5, 0xC(r3)
    stw r5, 0x8(r4)
    stw r5, 0xC(r4)
    */

    /*
    # Get randall's map_gobj
    li r3, 2                                            # randalls map_gobj is 2
    branchl r12, Stage_map_gobj_Load
    branchl r12, Stage_Destroy_map_gobj
    */

    # Get shyguy's map_gobj
    li r3, 3                                            # shyguys map_gobj is
    branchl r12, Stage_map_gobj_Load
    # Remove Proc
    branchl r12, GObj_RemoveProc

    # Fix ragdoll issue
    bl DisableHazards_RagdollFix

    b DisableHazards_SkipList_Exit

########################

DisableHazards_Pstadium:
    # Get transformation's map_gobj
    li r3, 2                                            # transformation's map_gobj ID
    branchl r12, Stage_map_gobj_Load
    # Remove Proc
    branchl r12, GObj_RemoveProc
    # Fix ragdoll issue
    bl DisableHazards_RagdollFix

    b DisableHazards_SkipList_Exit

########################

DisableHazards_OldDL:
    # Destroy whispy's map_gobj
    li r3, 7                                            # transformation's map_gobj ID
    branchl r12, Stage_map_gobj_Load
    branchl r12, Stage_Destroy_map_gobj

    # Destroy whispy's blink map_gobj proc
    li r3, 6                                            # transformation's map_gobj ID
    branchl r12, Stage_map_gobj_Load
    branchl r12, GObj_RemoveProc

    # set wind hazard count to 0
    li r3, 0
    stw r3, Stage_PositionHazardCount(r13)

    b DisableHazards_SkipList_Exit

########################

DisableHazards_OldYS:
    # Destroy cloud's map_gobj
    li r3, 2                                            # map_gobj ID
    branchl r12, Stage_map_gobj_Load
    branchl r12, Stage_Destroy_map_gobj

    b DisableHazards_SkipList_Exit

########################

DisableHazards_OldKongo:
    # Destroy barrel's map_gobj
    li r3, 1                                            # map_gobj ID
    branchl r12, Stage_map_gobj_Load
    branchl r12, Stage_Destroy_map_gobj

    b DisableHazards_SkipList_Exit

########################
DisableHazards_RagdollFix:
# Certain stages have an essential ragdoll function
# in their map_gobj think function. If the think function is removed,
# the ragdoll function must be re-scheduled to function properly.

    backup

    # Create GObj
    li r3, 3                                            # GObj Type
    li r4, 5                                            # On-Pause Function
    li r5, 0
    branchl r12, GObj_Create
    # Schedule Task
    bl DisableHazards_RagdollFix_Think
    mflr r4
    li r5, 4                                            # Priority
    branchl r12, GObj_AddProc
    b DisableHazards_RagdollFix_Exit

# ********************************#
DisableHazards_RagdollFix_Think:
    blrl

    backup

    branchl r12, Ragdoll_WindDecayThink

    restore
    blr

# ********************************#

DisableHazards_RagdollFix_Exit:
    restore
    blr

#########################

DisableHazards_SkipList_Exit:
    restore
    blr

###########################################

PlaybackInputSequence:
    .set REG_PlayerData, 31
    .set REG_InputSequence, 30
    .set REG_AttackTimer, 29

    # Input Sequence Struct
    .set InputSequence_Length, 0x9
    .set InputSequence_Frame, 0x0
    .set InputSequence_Buttons, 0x1
    .set InputSequence_AnalogX, 0x5
    .set InputSequence_AnalogY, 0x6
    .set InputSequence_CStickX, 0x7
    .set InputSequence_CStickY, 0x8

    backup

    # Backup args
    mr REG_PlayerData, r3
    mr REG_InputSequence, r4
    mr REG_AttackTimer, r5

PlaybackInputSequence_Loop:
    # Search for this frames input in the sequence
    lbz r3, InputSequence_Frame(REG_InputSequence)
    # Check if end of sequence
    extsb r0, r3
    cmpwi r0, -1
    beq PlaybackInputSequenceExit
    # Check if this frame's input
    cmpw r5, r3
    beq PlaybackInputSequence_PlayInput
    blt PlaybackInputSequenceExit                       # Check if the current frame is less than the parsed frame
    # If greater, continue parsing
    addi REG_InputSequence, REG_InputSequence, InputSequence_Length
    b PlaybackInputSequence_Loop                        # If greater, continue parsing

PlaybackInputSequence_PlayInput:
    lwz r3, InputSequence_Buttons(REG_InputSequence)
    stw r3, CPU_HeldButtons(REG_PlayerData)
    lbz r3, InputSequence_AnalogX(REG_InputSequence)
    stb r3, CPU_AnalogX(REG_PlayerData)
    lbz r3, InputSequence_AnalogY(REG_InputSequence)
    stb r3, CPU_AnalogY(REG_PlayerData)
    lbz r3, InputSequence_CStickX(REG_InputSequence)
    stb r3, CPU_CStickX(REG_PlayerData)
    lbz r3, InputSequence_CStickY(REG_InputSequence)
    stb r3, CPU_CStickY(REG_PlayerData)

PlaybackInputSequenceExit:
    restore
    blr

###########################################
PlaceOnLedge:
    backup

    .set REG_LedgeID, 31
    .set REG_P1GObj, 30
    .set REG_P1Data, 29

    # Backup pointers
    mr REG_P1GObj, r3
    lwz REG_P1Data, 0x2C(REG_P1GObj)
    mr REG_LedgeID, r4

    # Get Stage's Ledge IDs
    lwz r3, -0x6CB8(r13)                                # External Stage ID
    bl LedgeCliffIDs
    mflr r4
    mulli r3, r3, 0x2
    lhzx r3, r3, r4
    # Get Requested Ledge
    cmpwi REG_LedgeID, 0x0
    beq PlaceOnLedge_GetLeftLedgeID

PlaceOnLedge_GetRightLedgeID:
    rlwinm r20, r3, 0, 24, 31
    # Change Facing Direction
    li r3, -1
    bl IntToFloat
    stfs f1, 0x2C(REG_P1Data)
    b PlaceOnLedge_StoreLedgeIDAndPosition

PlaceOnLedge_GetLeftLedgeID:
    rlwinm r20, r3, 24, 24, 31
    # Change Facing Direction
    li r3, 1
    bl IntToFloat
    stfs f1, 0x2C(REG_P1Data)
    b PlaceOnLedge_StoreLedgeIDAndPosition

PlaceOnLedge_StoreLedgeIDAndPosition:
    # Store Ledge to Player Block
    stw r20, 0x2340(REG_P1Data)
    # Enter CliffWait
    mr r3, REG_P1GObj
    branchl r12, AS_CliffWait
    # Init state variable (would be 1 at the start of the next frame if it ocurred naturally)
    li r3, 1
    stw r3, 0x2348(REG_P1Data)
    # Spoof in state for 1 frame
    li r3, 1
    sth r3, TM_FramesinCurrentAS(REG_P1Data)
    # Get Jump Back
    mr r3, REG_P1Data
    branchl r12, Air_StoreBool_LoseGroundJump_NoECBfor10Frames
    # Set ECB Update Flag
    mr r3, REG_P1Data
    branchl r12, DataOffset_ECBBottomUpdateEnable
    # Update ECB Corner Positions
    addi r3, REG_P1Data, 0x6F0
    branchl r12, 0x80048160
    # Move Player To Ledge
    mr r3, REG_P1GObj
    branchl r12, MovePlayerToLedge
    # Update Position
    mr r3, REG_P1GObj
    bl UpdatePosition
    # Kill Velocity
    li r3, 0x0
    stw r3, 0x80(REG_P1Data)                            # X Velocity
    stw r3, 0x84(REG_P1Data)                            # Y Velocity

    # Give Intangibility (30)
    mr r3, REG_P1GObj
    lwz r4, -0x514C(r13)
    lwz r4, 0x049C(r4)
    branchl r12, ApplyIntangibility

    restore
    blr

###########################################
GetInputStruct:
    load r4, InputStructStart
    mulli r0, r3, 68
    add r3, r0, r4
    blr

###########################################
exit:
    li r0, 3
