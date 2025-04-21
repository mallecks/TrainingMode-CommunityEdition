################################
## Combo Training HIJACK INFO ##
################################

ComboTraining:
    # Store Stage, CPU, and FDD Toggles
    lwz r3, 0x0(r29)                                    # Send event struct
    mr r4, r26                                          # Send match struct
    li r5, -1                                           # Use chosen CPU
    li r6, -1                                           # Use chosen Stage
    load r7, EventOSD_ComboTraining
    li r8, 0                                            # Use Sopo bool
    bl InitializeMatch

    # STORE THINK FUNCTION
    bl ComboTrainingLoad
    mflr r3
    stw r3, 0x44(r26)                                   # on match load

    b exit

########################
## Combo Training LOAD FUNCT ##
########################
ComboTrainingLoad:
    blrl

    backup

    # Schedule Think
    bl ComboTrainingThink
    mflr r3
    li r4, 3                                            # Priority (After Interrupt)
    bl ComboTrainingWindowInfo                          # r4 = pointer to option info
    mflr r5
    bl ComboTrainingWindowText                          # r5 = pointer to ASCII struct
    mflr r6
    bl CreateEventThinkFunction

    bl InitializeHighScore

    b ComboTrainingLoadExit

#########################
## Combo Training THINK FUNCT ##
#########################

    # Registers
    .set MenuData, 26
    .set EventData, 31
    .set P1Data, 27
    .set P1GObj, 28
    .set P2Data, 29
    .set P2GObj, 30

    # Offsets
    .set EventState, 0x8
    .set DIBehavior, (MenuData_OptionMenuMemory+0x2)+0x0
    .set SDIBehavior, (MenuData_OptionMenuMemory+0x2)+0x1
    .set TechOption, (MenuData_OptionMenuMemory+0x2)+0x2
    .set PostHitstunAction, (MenuData_OptionMenuMemory+0x2)+0x3
    .set GrabMashout, (MenuData_OptionMenuMemory+0x2)+0x4
    .set DIBehaviorToggled, (MenuData_OptionMenuToggled)+0x0
    .set SDIBehaviorToggled, (MenuData_OptionMenuToggled)+0x1
    .set TechOptionToggled, (MenuData_OptionMenuToggled)+0x2
    .set PostHitstunActionToggled, (MenuData_OptionMenuToggled)+0x3
    .set GrabMashoutToggled, (MenuData_OptionMenuToggled)+0x4

    # Definitions
    # DIBehavior
    .set DI_Random, 0x0
    .set DI_Survival, 0x1
    .set DI_ComboDI, 0x2
    .set DI_SlightDIRandom, 0x3
    .set DI_SlightDIInwards, 0x4
    .set DI_DownAndAway, 0x5
    .set DI_None, 0x6
    # SDIBehavior
    .set SDI_33Percent, 0x0
    .set SDI_66Percent, 0x1
    .set SDI_Always, 0x2
    .set SDI_None, 0x3

ComboTrainingThink:
    blrl
    backup

    # INIT FUNCTION VARIABLES
    lwz r31, 0x2c(r3)                                   # backup data pointer in r31

    bl GetAllPlayerPointers
    mr P1GObj, r3
    mr P1Data, r4
    mr P2GObj, r5
    mr P2Data, r6

    lwz MenuData, EventData_MenuDataPointer(EventData)

    bl StoreCPUTypeAndZeroInputs

    # ON FIRST FRAME
    bl CheckIfFirstFrame
    cmpwi r3, 0x0
    beq ComboTrainingThinkMain

    bl StageGetGroundID_Main
    bl PlacePlayersCenterStage
    # Clear Inputs
    bl RemoveFirstFrameInputs
    # Save State
    addi r3, EventData, EventData_SaveStateStruct
    li r4, 1                                            # Override failsafe code
    bl SaveState_Save
    # Init Score Count
    lhz r3, -0x4ea8(r13)
    branchl r12, HUD_KOCounter_UpdateKOs

ComboTrainingThinkMain:
    # Set Combo As Score
    li r3, 0x0
    branchl r12, 0x8004134c
    sth r3, -0x4ea8(r13)
    # Check To Make New High Score
    lhz r3, -0x4ea8(r13)
    lhz r4, -0x4ea6(r13)
    cmpw r3, r4
    ble ComboTraining_SkipNewHighscore
    # Copy To High Score
    sth r3, -0x4ea6(r13)

ComboTraining_SkipNewHighscore:
    # Update HUD Score
    lhz r3, -0x4ea8(r13)
    cmpwi r3, 0x1
    blt ComboTraining_SkipHUDUpdate
    branchl r12, HUD_KOCounter_UpdateKOs

ComboTraining_SkipHUDUpdate:
    # DPad Right Makes New Savestate
    # Check If Trying to SaveState
    lwz r3, 0x668(r27)
    rlwinm. r0, r3, 0, 30, 30
    beq ComboTraining_CheckForSaveAndLoad
    # Only Allow a Save If Event State is 0
    lbz r3, EventState(r31)
    cmpwi r3, 0x0
    bne ComboTraining_SkipCheckForSaveAndLoad
    # Only Allow a Save If P2 is in Wait
    lwz r3, 0x10(r29)
    cmpwi r3, 0xE
    bne ComboTraining_SkipCheckForSaveAndLoad

ComboTraining_CheckForSaveAndLoad:
    addi r3, EventData, 0x10
    bl CheckForSaveAndLoad
    # Check If Loaded Successfully
    cmpwi r3, 0x1
    bne ComboTraining_SkipCheckForSaveAndLoad
    # Restore Event State And Timer
    li r3, 0x0
    stb r3, EventState(r31)
    stw r3, 0x4(r31)

ComboTraining_SkipCheckForSaveAndLoad:
    # DPad Down Moves CPU In Front
    # Only If Event State = 0
    lbz r3, EventState(r31)
    cmpwi r3, 0x0
    bne ComboTrainingSkipMoveCPU
    mr r3, P1GObj
    mr r4, P2GObj
    addi r5, EventData, 0x10
    bl MoveCPU

ComboTrainingSkipMoveCPU:
    # L+DPad Controls CPU Percent
    addi r3, EventData, EventData_SaveStateStruct+(1*0x8)
    bl DPadCPUPercent

    bl GiveFullShields

    # Reset If Anyone Dies
    bl IsAnyoneDead
    cmpwi r3, 0x0
    bne ComboTrainingRestoreState

############################
## Check If Was Hit Again ##
############################

    # Don't Run If Over 6 Frames in Escape Air
    lwz r3, 0x10(r29)
    cmpwi r3, 0xEC
    bne ComboTrainingCheckIfP2isGrabbed
    li r3, 6
    bl IntToFloat
    lfs f2, 0x894(r29)
    fcmpo cr0, f1, f2
    bge ComboTrainingCheckState

# Check If P2 is Grabbed (Any Grab State)
ComboTrainingCheckIfP2isGrabbed:
    lwz r3, 0x10(r29)
    cmpwi r3, 0xDF
    blt ComboTrainingStartCheckIfHit
    cmpwi r3, 0xE8
    bgt ComboTrainingStartCheckIfHit
    b ComboTrainingChangeToRandomDIandTech

# Check If P2 is Hit
ComboTrainingStartCheckIfHit:
    lbz r3, 0x221A(r29)                                 # Check If in Hitlag
    rlwinm. r3, r3, 0, 26, 26
    bne ComboTrainingCheckIfBeingHit
    b ComboTrainingCheckState

ComboTrainingCheckIfBeingHit:
    lwz r3, 0x10(r29)
    cmpwi r3, ASID_DamageHi1
    blt ComboTrainingCheckState
    cmpwi r3, ASID_DamageFlyRoll
    bgt ComboTrainingCheckState

ComboTrainingChangeToRandomDIandTech:
    # Change To DI and Tech
    li r3, 0x1
    stb r3, EventState(r31)
    b ComboTrainingInputDIAndTech

# Get Which State
ComboTrainingCheckState:
    lbz r3, EventState(r31)
    cmpwi r3, 0x0
    beq ComboTrainingStart
    cmpwi r3, 0x1
    beq ComboTrainingInputDIAndTech
    cmpwi r3, 0x2
    beq ComboTrainingPostHitstun

ComboTrainingStart:
    b ComboTrainingCheckToReset

ComboTrainingInputDIAndTech:
    bl ComboTrainingCheckExitStates
    cmpwi r3, 0x0
    beq ComboTrainingInputDIAndTechNoJiggs
    b ComboTrainingChangeStateToPostHitstun

ComboTrainingInputDIAndTechNoJiggs:
    lwz r3, 0x10(r29)
    cmpwi r3, 0xB8                                      # Missed Tech, Needs to Input a Roll or Attack
    beq ComboTrainingMissedTechThink
    cmpwi r3, 0xC0                                      # Missed Tech, Needs to Input a Roll or Attack
    beq ComboTrainingMissedTechThink

    # Check If Still Grabbed
    cmpwi r3, ASID_ShoulderedWait
    blt ComboTraining_GrabCheckCargoThrow
    cmpwi r3, ASID_ShoulderedTurn
    ble ComboTrainingMashOutOfGrab

ComboTraining_GrabCheckCargoThrow:
    lwz r4, 0x4(r27) # get char ID
    cmpwi r4, DK.Int
    bne ComboTraining_GrabCheckSkipShoulder
    cmpwi r3, ASID_ThrownF
    beq ComboTrainingMashOutOfGrab
    cmpwi r3, ASID_ThrownFF
    beq ComboTrainingMashOutOfGrab

ComboTraining_GrabCheckSkipShoulder:
    cmpwi r3, ASID_CaptureKoopa
    blt ComboTraining_GrabCheckSkipKoopaLw
    cmpwi r3, ASID_CaptureWaitKoopa
    ble ComboTrainingMashOutOfGrab

ComboTraining_GrabCheckSkipKoopaLw:
    cmpwi r3, ASID_CaptureKoopaAir
    blt ComboTraining_GrabCheckSkipKoopaAir
    cmpwi r3, ASID_CaptureWaitKoopaAir
    ble ComboTrainingMashOutOfGrab

ComboTraining_GrabCheckSkipKoopaAir:
    cmpwi r3, ASID_CapturePulledHi                      # CapturePulledLow
    blt ComboTraining_GrabCheckSkipGrabbed
    cmpwi r3, ASID_CaptureFoot                          # CapturePulledHi
    ble ComboTrainingMashOutOfGrab

ComboTraining_GrabCheckSkipGrabbed:
    b ComboTrainingDecideInputs

# When Grabbed
# Check Mash Out Behavior
ComboTrainingMashOutOfGrab:
    lbz r3, GrabMashout(MenuData)
    cmpwi r3, 0x0
    beq ComboTrainingInputDIAndTech_RandomMash
    cmpwi r3, 0x1
    beq ComboTrainingInputDIAndTech_RandomMash_AnalogInput
    cmpwi r3, 0x2                                       # No Mash
    beq ComboTrainingCheckToReset

# Random Mash Out
ComboTrainingInputDIAndTech_RandomMash:
    # Only start randomly mashing after a few frames (to simulate human reaction)
    lwz r3, 0x10(r29)
    cmpwi r3, ASID_CapturePulledHi                      # CapturePulledLow
    blt ComboTrainingInputDIAndTech_RandomMashStart
    cmpwi r3, ASID_CaptureFoot                          # CapturePulledHi
    bgt ComboTrainingInputDIAndTech_RandomMashStart

# In a normal grab state, should wait a few frames before starting to mash

ComboTrainingInputDIAndTech_RandomMashStart:
    li r3, 10                                           # 1- Numbers
    branchl r12, HSD_Randi
    cmpwi r3, 7                                         # 7 and below are no input
    ble ComboTrainingCheckToReset
    cmpwi r3, 8                                         # 8 = Button Only, 9 = Both Analog and Button
    beq ComboTrainingInputDIAndTech_RandomMash_ButtonPress

ComboTrainingInputDIAndTech_RandomMash_AnalogInput:
    li r3, 127
    stb r3, 0x1A8C(r29)                                 # Push Analog Stick Forward
    li r3, -1
    stb r3, 0x1A50(r29)                                 # Spoof Analog Stick as First Frame Pushed

ComboTrainingInputDIAndTech_RandomMash_ButtonPress:
    # Input Button Press
    li r3, 0x100
    stw r3, 0x1A88(r29)                                 # Press A
    li r3, 0
    stw r3, 0x65C(r29)                                  # Spoof Prev Frame Buttons as Nothing Pushed

    b ComboTrainingCheckToReset

ComboTrainingChangeStateToPostHitstun:
    # Change State
    li r3, 0x2
    stb r3, EventState(r31)
    b ComboTrainingPostHitstun

ComboTrainingDecideInputs:
# CHECK TO DI ATTACK
ComboTrainingDIThrowsAndHits:
    # Check If in Hitlag
    lbz r3, 0x221A(r29)
    rlwinm. r3, r3, 0, 26, 26
    beq ComboTrainingCheckIfBeingThrown
    # Check If In Last Frame of Hitlag
    lfs f1, -0x7418(rtoc)                               # 1fp
    lfs f2, 0x195C(r29)                                 # hitlag frames left
    fcmpo cr0, f1, f2
    bne ComboTrainingCheckToReset
    # Check If Attack Was Strong
    # DI Attack
    lbz r3, DIBehavior(MenuData)                        # Get DI Behavior
    cmpwi r3, DI_SlightDIInwards                        # Check If Slight In
    bne 0x8
    li r3, 0x0                                          # Override To Never Slight DI In Attacks
    b 0x8
    li r3, 0x2
    bl ComboTrainingDecideStickAngle
    # SDI Attack
    lbz r3, SDIBehavior(MenuData)                       # Get SDI Behavior
    cmpwi r3, SDI_None                                  # No SDI
    beq ComboTrainingNoSDI
    cmpwi r3, SDI_Always                                # Always SDI
    beq ComboTrainingCheckToReset

    li r3, 0x3
    branchl r12, HSD_Randi
    lbz r4, SDIBehavior(MenuData)                       # Get SDI Behavior
    cmpwi r4, SDI_33Percent
    beq ComboTraining33PercentSDI
    cmpwi r4, SDI_66Percent
    beq ComboTraining66PercentSDI

ComboTraining33PercentSDI:
    li r4, 0
    b ComboTrainingCompareSDIChance

ComboTraining66PercentSDI:
    li r4, 1
    b ComboTrainingCompareSDIChance

ComboTrainingCompareSDIChance:
    cmpw r3, r4
    ble ComboTrainingGetChanceToTech

# Don't SDI
ComboTrainingNoSDI:
    mr r3, r29
    branchl r12, CPU_JoystickXAxis_Convert
    stfs f1, 0x620(r29)
    mr r3, r29
    branchl r12, CPU_JoystickYAxis_Convert
    stfs f1, 0x624(r29)
    b ComboTrainingGetChanceToTech

# CHECK TO DI A THROW
ComboTrainingCheckIfBeingThrown:
    lwz r3, 0x10(r29) # cpu state

ComboTrainingCheckIfBeingThrown_CheckCargoThrow:
    lwz r4, 0x4(r27) # get char ID
    cmpwi r4, DK.Int
    bne ComboTrainingCheckIfBeingThrown_CheckNormalThrows
    cmpwi r3, ASID_ThrownF
    beq ComboTrainingCheckToJumpOutOfHitstun
    cmpwi r3, ASID_ThrownFF
    beq ComboTrainingCheckToJumpOutOfHitstun

ComboTrainingCheckIfBeingThrown_CheckNormalThrows:
    cmpwi r3, ASID_ThrownF
    blt ComboTrainingCheckIfBeingThrown_CheckFThrows
    cmpwi r3, ASID_ThrownLwWomen
    bgt ComboTrainingCheckIfBeingThrown_CheckFThrows
    b ComboTrainingInputDI

ComboTrainingCheckIfBeingThrown_CheckFThrows:
    cmpwi r3, ASID_ThrownFF
    blt ComboTrainingCheckToJumpOutOfHitstun
    cmpwi r3, ASID_ThrownFLw
    bgt ComboTrainingCheckToJumpOutOfHitstun
    b ComboTrainingInputDI

ComboTrainingInputDI:
    lbz r3, DIBehavior(MenuData)
    bl ComboTrainingDecideStickAngle
    b ComboTrainingCheckToReset

# NOT BEING THROWN OR LAST FRAME OF HITLAG
# CHECK TO JUMP OUT OF HITSTUN AND BECOME INVINCIBLE
ComboTrainingCheckToJumpOutOfHitstun:
    # Check If in Damage State
    lwz r3, 0x10(r29)
    cmpwi r3, 0x26                                      # Tumble
    beq ComboTrainingCheckIfInAir
    cmpwi r3, 0x4B
    blt ComboTrainingCheckToReset
    cmpwi r3, 0x5B
    bgt ComboTrainingCheckToReset

# IN A DAMAGE STATE
# Check If In Air
ComboTrainingCheckIfInAir:
    lwz r3, 0xE0(r29)
    cmpwi r3, 0x0
    beq ComboTrainingDamageGrounded

    # IN THE AIR
    # Check If Still in Hitstun
    lbz r3, 0x221C(r29)
    rlwinm. r3, r3, 0, 30, 30
    bne ComboTrainingGetChanceToTech

    # NOT IN HITSTUN
    # Check Post Hitstun Behavior
    lbz r3, PostHitstunAction(MenuData)
    cmpwi r3, 0x0
    beq ComboTrainingAirdodge
    cmpwi r3, 0x1
    beq ComboTrainingJumpAndInvincible
    cmpwi r3, 0x2
    beq ComboTrainingAerialAttack

ComboTrainingJumpAndInvincible:
    # Always Jump
    # li r3, 0
    # stw r3, 0x1A8C(r29) #Nuetralize Stick Inputs
    # i r3, 0x400
    # stw r3, 0x1A88(r29) #X Button
    b ComboTrainingChangeStateToPostHitstun

ComboTrainingAirdodge:
    # Wiggle Out of Hitstun
    li r3, 127
    stb r3, 0x1A8C(r29)
    # Last Frame's Stick Was Centered
    li r3, 0x0
    stw r3, 0x628(r29)
    stw r3, 0x62C(r29)
    # Stick Frame Timer Reset
    li r3, 255
    stb r3, 0x670(r29)
    # Change State
    li r3, 0x2
    stb r3, 0x8(r31)
    b ComboTrainingPostHitstun

ComboTrainingAerialAttack:
    # li r3, 0x100
    # stw r3, 0x1A88(r29) #Nair
    # Change State
    li r3, 0x2
    stb r3, EventState(r31)
    b ComboTrainingPostHitstun

# CHECK TO BECOME INVINCIBLE OUT OF GROUNDED LIGHT DAMAGE STATES
ComboTrainingDamageGrounded:
    # Check For Hitstun (Can Act Out of Certain Light Damage States)
    lbz r3, 0x221C(r29)
    rlwinm. r3, r3, 0, 30, 30
    bne ComboTrainingCheckToReset
    # Grounded, No Hitstun Left, Become Invincible and Spotdodge
    # Check Post Hitstun Behavior
    lbz r3, PostHitstunAction(MenuData)
    cmpwi r3, 0x0
    beq ComboTrainingGroundedSpotdodge
    cmpwi r3, 0x1
    beq ComboTrainingGroundedInvincibility
    cmpwi r3, 0x2
    beq ComboTrainingGroundedAttack

ComboTrainingGroundedInvincibility:
    b ComboTrainingChangeStateToPostHitstun

ComboTrainingGroundedSpotdodge:
    li r3, 0xC0                                         # Hit L
    stw r3, 0x1A88(r29)                                 # Held Buttons
    li r3, -127                                         # Hold Down
    stb r3, 0x1A8D(r29)                                 # Stick Y
    b ComboTrainingChangeStateToPostHitstun

ComboTrainingGroundedAttack:
    # li r3, 0x100 #Hit A
    # stw r3, 0x1A88(r29) #Held Buttons
    b ComboTrainingChangeStateToPostHitstun

ComboTrainingGetChanceToTech:
    # INPUT A TECH WHEN IN AERIAL HITSTUN
    lbz r3, TechOption(MenuData)                        # Get Tech Behavior
    cmpwi r3, 0x0                                       # Random Tech (Original Behavior)
    beq ComboTrainingRandomTech
    cmpwi r3, 0x1                                       # Miss Tech
    beq ComboTrainingMissTech
    cmpwi r3, 0x2
    beq ComboTrainingTechInPlace
    cmpwi r3, 0x3
    beq ComboTrainingTechTowards
    cmpwi r3, 0x4
    beq ComboTrainingTechAway

ComboTrainingRandomTech:
    # Reset Tech Cooldown Window Constantly
    li r3, 0x1
    stb r3, 0x680(r29)                                  # Frames Since Pressed L/R
    li r3, 0xFF
    stb r3, 0x684(r29)                                  # L/R Lockout Window
    # Check If In Hitlag Before Inputting Random Side (Messes Up DI Otherwise)
    lbz r3, 0x221A(r29)
    rlwinm. r3, r3, 0, 26, 26
    bne ComboTrainingCheckToReset

# Tech Random Side
ComboTrainingRandomTech_GetStickAngle:
    li r3, 4                                            # Decide between left right and center and none
    branchl r12, HSD_Randi
    cmpwi r3, 0x0
    beq ComboTrainingRandomTech_TechInPlace
    cmpwi r3, 0x1
    beq ComboTrainingRandomTech_TechLeft
    cmpwi r3, 0x2
    beq ComboTrainingRandomTech_TechRight
    cmpwi r3, 0x3
    beq ComboTrainingMissTech

ComboTrainingRandomTech_TechInPlace:
    li r3, 0
    stb r3, 0x1A8C(r29)
    stb r3, 0x1A8D(r29)
    b ComboTrainingCheckToReset

ComboTrainingRandomTech_TechLeft:
    li r3, -127
    stb r3, 0x1A8C(r29)
    b ComboTrainingCheckToReset

ComboTrainingRandomTech_TechRight:
    li r3, 127
    stb r3, 0x1A8C(r29)
    b ComboTrainingCheckToReset

ComboTrainingMissTech:
    li r3, 0x0
    stw r3, 0x1A88(r29)
    # Fail Tech Cooldown
    li r3, 0xFF
    stb r3, 0x680(r29)
    li r3, 0x00
    stb r3, 0x684(r29)
    b ComboTrainingCheckToReset

ComboTrainingTechInPlace:
    # Hold L
    li r3, 0xC0
    stw r3, 0x1A88(r29)
    # Reset Tech Cooldown Window Constantly
    li r3, 0x0
    stb r3, 0x680(r29)
    li r3, 0xFF
    stb r3, 0x684(r29)
    # Check If In Hitlag Before Inputting Random Side (Messes Up DI Otherwise)
    lbz r3, 0x221A(r29)
    rlwinm. r3, r3, 0, 26, 26
    bne ComboTrainingCheckToReset
    li r3, 0x0
    stb r3, 0x1A8C(r29)
    b ComboTrainingCheckToReset

ComboTrainingTechTowards:
    # Hold L
    li r3, 0xC0
    stw r3, 0x1A88(r29)
    # Reset Tech Cooldown Window Constantly
    li r3, 0x0
    stb r3, 0x680(r29)
    li r3, 0xFF
    stb r3, 0x684(r29)
    # Check If In Hitlag Before Inputting Random Side (Messes Up DI Otherwise)
    lbz r3, 0x221A(r29)
    rlwinm. r3, r3, 0, 26, 26
    bne ComboTrainingCheckToReset
    # Push Towards Opponent's Direction
    bl GetDirectionInRelationToP1
    mulli r3, r3, -1                                    # Negate This
    li r4, 127
    mullw r3, r3, r4
    stb r3, 0x1A8C(r29)
    b ComboTrainingCheckToReset

ComboTrainingTechAway:
    # Hold L
    li r3, 0xC0
    stw r3, 0x1A88(r29)
    # Reset Tech Cooldown Window Constantly
    li r3, 0x0
    stb r3, 0x680(r29)
    li r3, 0xFF
    stb r3, 0x684(r29)
    # Check If In Hitlag Before Inputting Random Side (Messes Up DI Otherwise)
    lbz r3, 0x221A(r29)
    rlwinm. r3, r3, 0, 26, 26
    bne ComboTrainingCheckToReset
    bl GetDirectionInRelationToP1
    li r4, 127
    mullw r3, r3, r4
    stb r3, 0x1A8C(r29)
    b ComboTrainingCheckToReset

# INPUT AN ATTACK OR DIRECTION WHEN MISSED A TECH
ComboTrainingMissedTechThink:
    li r3, 4                                            # 1/4 chance to getup attack
    branchl r12, HSD_Randi
    cmpwi r3, 0x0
    beq ComboTrainingMissedTech_GetupAttack
    # No Getup Attack, Input Random Direction
    li r3, 0
    bl ComboTrainingDecideStickAngle
    b ComboTrainingCheckToReset

# Input Getup Attack
ComboTrainingMissedTech_GetupAttack:
    li r3, 0x100                                        # Press A To Getup Attack
    stw r3, 0x1A88(r29)
    b ComboTrainingCheckToReset

########################
## Post Hitstun Think ##
########################

ComboTrainingPostHitstun:
    # Check Post Hitstun Behavior
    lbz r3, PostHitstunAction(MenuData)
    cmpwi r3, 0x0
    beq ComboTrainingPostHitstun_AirdodgeSpotdodge
    cmpwi r3, 0x1
    beq ComboTrainingPostHitstun_GiveInvinc
    cmpwi r3, 0x2
    beq ComboTrainingPostHitstun_Attack

ComboTrainingPostHitstun_GiveInvinc:
    # Constantly Press Jump If In The Air
    lwz r3, 0xE0(r29)
    cmpwi r3, 0x0
    beq ComboTrainingPostHitstun_GiveInvinc_ApplyInvinc
    li r3, 0x800
    stw r3, 0x1A88(r29)
    # Clear Prev Frame Jump Input
    li r3, 0x0
    stw r3, 0x668(r29)

# Apply Invinc
ComboTrainingPostHitstun_GiveInvinc_ApplyInvinc:
    mr r3, r30
    li r4, 30
    branchl r12, ApplyIntangibility
    # UpdateGFX
    mr r3, r30
    branchl r12, GFX_UpdatePlayerGFX
    # Set Timer if Not Set
    lwz r3, 0x4(r31)
    cmpwi r3, 0x0
    bgt ComboTrainingCheckToReset
    # Set Timer
    li r3, 30
    stw r3, 0x4(r31)
    b ComboTrainingCheckToReset

# ****************************************************************#

ComboTrainingPostHitstun_AirdodgeSpotdodge:
    # Check If In Airdodge
    # Check If In Gained Invuln From Air/Spotdodge
    lwz r3, 0x1988(r29)
    cmpwi r3, 0x0
    beq ComboTrainingPostHitstun_AirdodgeSpotdodge_CheckToAirdodge
    b ComboTrainingPostHitstun_EnteredAirdodgeSpotdodge

ComboTrainingPostHitstun_EnteredAirdodgeSpotdodge:
    # Set Timer if Not Set
    lwz r3, 0x4(r31)
    cmpwi r3, 0x0
    bgt ComboTrainingCheckToReset
    # Set Timer
    li r3, 30
    stw r3, 0x4(r31)
    # Give Invince and Exit
    b ComboTrainingCheckToReset

# ****************************************************************#

ComboTrainingPostHitstun_AirdodgeSpotdodge_CheckToAirdodge:
    # If in An Exit State, Reset State
    bl ComboTrainingCheckExitStates
    cmpwi r3, 0x0
    beq ComboTrainingPostHitstun_AirdodgeSpotdodge_CheckAirState
    # Except Fall
    lwz r3, 0x10(r29)
    cmpwi r3, 0x1D
    beq ComboTrainingPostHitstun_AirdodgeSpotdodge_CheckAirState
    # Except Landing
    cmpwi r3, 0x2A
    beq ComboTrainingPostHitstun_AirdodgeSpotdodge_CheckAirState
    # Except Wait
    cmpwi r3, 0xE
    beq ComboTrainingPostHitstun_AirdodgeSpotdodge_CheckAirState
    # Set Timer if Not Set
    lwz r3, 0x4(r31)
    cmpwi r3, 0x0
    bgt ComboTrainingCheckToReset
    # Set Timer
    li r3, 30
    stw r3, 0x4(r31)

ComboTrainingPostHitstun_AirdodgeSpotdodge_CheckAirState:
    # Check If in Air
    lwz r3, 0xE0(r29)
    cmpwi r3, 0x0
    beq ComboTrainingPostHitstun_AirdodgeSpotdodge_CheckToAirdodge_CheckToSpotdodge
    # Check If In DamageLightHit With No Hitstun Left (Same interrupts as Fall)
    lwz r3, 0x10(r29)
    cmpwi r3, 0x56
    beq ComboTrainingPostHitstun_AirdodgeSpotdodge_CheckAirState_InputAirdodge

ComboTrainingPostHitstun_AirdodgeSpotdodge_CheckAirState_CheckToWiggleOut:
    # Check If In Damage States
    lwz r3, 0x10(r29)
    cmpwi r3, 0x4B
    blt ComboTrainingPostHitstun_AirdodgeSpotdodge_CheckAirState_CheckForFall
    cmpwi r3, 0x5B
    bgt ComboTrainingPostHitstun_AirdodgeSpotdodge_CheckAirState_CheckForFall
    # Wiggle Out to Enter Fall
    li r3, 127
    stb r3, 0x1A8C(r29)
    b ComboTrainingCheckToReset

# Check If In Fall
ComboTrainingPostHitstun_AirdodgeSpotdodge_CheckAirState_CheckForFall:
    lwz r3, 0x10(r29)
    cmpwi r3, 0x1D
    bne ComboTrainingCheckToReset

ComboTrainingPostHitstun_AirdodgeSpotdodge_CheckAirState_InputAirdodge:
    # Airdodge
    li r3, 0
    stb r3, 0x1A8C(r29)
    li r3, 0xC0
    stw r3, 0x1A88(r29)
    # Clear Buttons From Last Frame
    li r3, 0x0
    stw r3, 0x65C(r29)
    b ComboTrainingCheckToReset

ComboTrainingPostHitstun_AirdodgeSpotdodge_CheckToAirdodge_CheckToSpotdodge:
    # Check If Grounded and Actionable
    lwz r3, 0x10(r29)
    cmpwi r3, 0xE                                       # Wait
    beq ComboTrainingPostHitstun_AirdodgeSpotdodge_CheckToAirdodge_Spotdodge
    cmpwi r3, 0xB6                                      # Shielding
    beq ComboTrainingPostHitstun_AirdodgeSpotdodge_CheckToAirdodge_Spotdodge
    cmpwi r3, 0x2A                                      # Land
    bne ComboTrainingCheckToReset
    # Check If Can Interrupt Land
    lfs f1, 0x894(r29)
    lfs f2, 0x1F4(r29)
    fcmpo cr0, f1, f2
    blt ComboTrainingCheckToReset

ComboTrainingPostHitstun_AirdodgeSpotdodge_CheckToAirdodge_Spotdodge:
    # Clear Buttons From Last Frame
    li r3, 0x0
    stw r3, 0x65C(r29)
    # Input Spotdodge
    li r3, 0xC0
    stw r3, 0x1A88(r29)
    li r3, -127
    stb r3, 0x1A8D(r29)
    b ComboTrainingCheckToReset

# ****************************************************************#

ComboTrainingPostHitstun_Attack:
    # Clear Buttons From Last Frame
    li r3, 0x0
    stw r3, 0x65C(r29)

    # Get Air or Ground
    lwz r3, 0xE0(r29)
    cmpwi r3, 0x0
    beq ComboTrainingPostHitstun_AttackGround

ComboTrainingPostHitstun_AttackAir:
    bl ComboTrainingAttackList
    mflr r5
    lwz r4, 0x4(r29)
    lbzx r3, r4, r5
    rlwinm r3, r3, 0, 28, 31                            # Get Right Bits
    b ComboTrainingPostHitstun_Attack_BranchToAttack

ComboTrainingPostHitstun_AttackGround:
    bl ComboTrainingAttackList
    mflr r5
    lwz r4, 0x4(r29)
    lbzx r3, r4, r5
    rlwinm r3, r3, 28, 28, 31                           # Get Left Bits
    b ComboTrainingPostHitstun_Attack_BranchToAttack

ComboTrainingPostHitstun_Attack_BranchToAttack:
    cmpwi r3, 0x0
    beq ComboTrainingPostHitstun_Attack_A
    cmpwi r3, 0x1
    beq ComboTrainingPostHitstun_Attack_ForwardA
    cmpwi r3, 0x2
    beq ComboTrainingPostHitstun_Attack_BackA
    cmpwi r3, 0x3
    beq ComboTrainingPostHitstun_Attack_DownA
    cmpwi r3, 0x4
    beq ComboTrainingPostHitstun_Attack_UpA
    cmpwi r3, 0x5
    beq ComboTrainingPostHitstun_Attack_DownSmash
    cmpwi r3, 0x6
    beq ComboTrainingPostHitstun_Attack_UpB
    cmpwi r3, 0x7
    beq ComboTrainingPostHitstun_Attack_DownB

ComboTrainingPostHitstun_Attack_A:
    li r3, 0x100                                        # Hit A
    stw r3, 0x1A88(r29)                                 # Held Buttons
    b ComboTrainingPostHitstun_Attack_CheckForHitbox

ComboTrainingPostHitstun_Attack_ForwardA:
    # Push Towards Opponent's Direction
    bl GetDirectionInRelationToP1
    mulli r3, r3, -1                                    # Negate This
    li r4, 60
    mullw r3, r3, r4
    stb r3, 0x1A8C(r29)
    li r3, 0x100                                        # Hit A
    stw r3, 0x1A88(r29)                                 # Held Buttons
    b ComboTrainingPostHitstun_Attack_CheckForHitbox

ComboTrainingPostHitstun_Attack_BackA:
    # Push Away Opponent's Direction
    bl GetDirectionInRelationToP1
    li r4, 60
    mullw r3, r3, r4
    stb r3, 0x1A8C(r29)
    li r3, 0x100                                        # Hit A
    stw r3, 0x1A88(r29)                                 # Held Buttons
    b ComboTrainingPostHitstun_Attack_CheckForHitbox

ComboTrainingPostHitstun_Attack_DownA:
    li r3, 60
    stb r3, 0x1A8D(r29)
    li r3, 0x100                                        # Hit A
    stw r3, 0x1A88(r29)                                 # Held Buttons
    b ComboTrainingPostHitstun_Attack_CheckForHitbox

ComboTrainingPostHitstun_Attack_UpA:
    li r3, 60
    stb r3, 0x1A8D(r29)
    li r3, 0x100                                        # Hit A
    stw r3, 0x1A88(r29)                                 # Held Buttons
    b ComboTrainingPostHitstun_Attack_CheckForHitbox

ComboTrainingPostHitstun_Attack_DownSmash:
    li r3, -127
    stb r3, 0x1A8F(r29)
    b ComboTrainingPostHitstun_Attack_CheckForHitbox

ComboTrainingPostHitstun_Attack_UpB:
    li r3, 127
    stb r3, 0x1A8D(r29)
    li r3, 0x200                                        # Hit B
    stw r3, 0x1A88(r29)                                 # Held Buttons
    b ComboTrainingPostHitstun_Attack_CheckForHitbox

ComboTrainingPostHitstun_Attack_DownB:
    li r3, -127
    stb r3, 0x1A8D(r29)
    li r3, 0x200                                        # Hit B
    stw r3, 0x1A88(r29)                                 # Held Buttons
    b ComboTrainingPostHitstun_Attack_CheckForHitbox

# Search For Active Hitbox
ComboTrainingPostHitstun_Attack_CheckForHitbox:
    mr r3, r30
    bl CheckForActiveHitboxes
    cmpwi r3, 0x0
    bne ComboTrainingPostHitstun_GiveInvinc_ApplyInvinc
    # Harcoded Fox Grounded Shine Check =(
    lwz r3, 0x4(r29)
    cmpwi r3, 0x1
    beq ComboTrainingPostHitstun_Attack_CheckForGroundShine
    cmpwi r3, 0x16
    beq ComboTrainingPostHitstun_Attack_CheckForGroundShine
    # Hardcoded Puff Rest Check =(
    cmpwi r3, 0xF
    beq ComboTrainingPostHitstun_Attack_CheckForRest
    b ComboTrainingCheckToReset

ComboTrainingPostHitstun_Attack_CheckForGroundShine:
    lwz r3, 0x10(r29)
    cmpwi r3, 0x168
    beq ComboTrainingPostHitstun_GiveInvinc_ApplyInvinc
    b ComboTrainingCheckToReset

ComboTrainingPostHitstun_Attack_CheckForRest:
    lwz r3, 0x10(r29)
    cmpwi r3, 0x171
    beq ComboTrainingPostHitstun_GiveInvinc_ApplyInvinc
    b ComboTrainingCheckToReset

# ****************************************************************#

# Check To Reset
ComboTrainingCheckToReset:
    lwz r3, 0x4(r31)                                    # get timer
    cmpwi r3, 0x0                                       # No Reset Timer Set Yet
    ble ComboTrainingThinkExit
    # Dec Timer
    subi r3, r3, 0x1
    stw r3, 0x4(r31)                                    # store timer
    cmpwi r3, 0x0                                       # Check if 0 now
    bne ComboTrainingThinkExit                          # Exit If Not

ComboTrainingRestoreState:
    # Restore State
    addi r3, EventData, EventData_SaveStateStruct
    bl SaveState_Load
    addi r3, EventData, EventData_SaveStateStruct
    bl SaveState_Load
    # Reset State ID
    li r3, 0x0
    stb r3, EventState(r31)

ComboTrainingThinkExit:
    mr r3, MenuData
    bl ClearToggledOptions
    bl UpdateAllGFX
    restore
    blr

#################################

StageGetGroundID_Main:
    mflr r5
    lwz r3, -0x6CB8(r13) # External Stage ID
    bl StageGroundIDs_Main
    mflr r4
    mulli r3, r3, 0x2
    lhzx r3, r3, r4
    mtlr r5
    blr

StageGetGroundID_Platform:
    mflr r5
    lwz r3, -0x6CB8(r13) # External Stage ID
    bl StageGroundIDs_Platform
    mflr r4
    mulli r3, r3, 0x2
    lhzx r3, r3, r4
    mtlr r5
    blr

StageGroundIDs_Main:
    blrl
    # Ground IDs to start on
    .long 0xFFFFFFFF                                    # Dummy, TEST
    .long 0x00050022                                    # FoD, Pokemon Stadium
    .long 0x00050037                                    # Peach's Castle, Kongo Jungle
    .long 0x000B0012                                    # Brinstar, Corneria
    .long 0x00030019                                    # Yoshi's Story, Onett
    .long 0x00000048                                    # Mute City, Rainbow Cruise
    .long 0x00000024                                    # Jungle Japes, Great Bay
    .long 0x00190007                                    # Hyrule Temple, Brinstar Depths
    .long 0x000E0026                                    # Yoshi's Island, Green Greens
    .long 0x00040003                                    # Fourside, MKI
    .long 0x00040000                                    # MKII, Akaneia
    .long 0x00010105                                    # Venom, PokeFloats
    .long 0x00D9015B                                    # Big Blue, Icicle Mountain
    .long 0x00000064                                    # Icetop, Flatzone
    .long 0x00040009                                    # Dream Land, Yoshis Island 64
    .long 0x000b0001                                    # Kongo Jungle 64, Battlefield
    .long 0x00010000                                    # Final Destination

StageGroundIDs_Platform:
    blrl
    # Ground IDs to start on
    .long 0xFFFFFFFF                                    # Dummy, TEST
    .long 0x00020023                                    # FoD, Pokemon Stadium
    .long 0xFFFFFFFF                                    # Peach's Castle, Kongo Jungle
    .long 0xFFFFFFFF                                    # Brinstar, Corneria
    .long 0x0004FFFF                                    # Yoshi's Story, Onett
    .long 0xFFFFFFFF                                    # Mute City, Rainbow Cruise
    .long 0xFFFFFFFF                                    # Jungle Japes, Great Bay
    .long 0xFFFFFFFF                                    # Hyrule Temple, Brinstar Depths
    .long 0xFFFFFFFF                                    # Yoshi's Island, Green Greens
    .long 0xFFFFFFFF                                    # Fourside, MKI
    .long 0xFFFFFFFF                                    # MKII, Akaneia
    .long 0xFFFFFFFF                                    # Venom, PokeFloats
    .long 0xFFFFFFFF                                    # Big Blue, Icicle Mountain
    .long 0xFFFFFFFF                                    # Icetop, Flatzone
    .long 0x0002FFFF                                    # Dream Land, Yoshis Island 64
    .long 0xFFFF0003                                    # Kongo Jungle 64, Battlefield
    .long 0xFFFFFFFF                                    # Final Destination

#################################

ComboTrainingDecideStickAngle:
    # Decide Stick Angle
    backup

    # Clear Stick Inputs Just in Case
    li r4, 0x0
    stb r4, 0x1A8C(r29)
    stb r4, 0x1A8D(r29)

    # Check Which Type Of DI To Perform
    cmpwi r3, DI_Random
    beq ComboTrainingDecideStickAngle_RandomDI
    cmpwi r3, DI_Survival
    beq ComboTrainingDecideStickAngle_SurvivalDI
    cmpwi r3, DI_ComboDI
    beq ComboTrainingDecideStickAngle_ComboDI
    cmpwi r3, DI_SlightDIRandom
    beq ComboTrainingDecideStickAngle_RandomDI_SlightDI
    cmpwi r3, DI_SlightDIInwards
    beq ComboTrainingDecideStickAngle_SlightDIInwards
    cmpwi r3, DI_DownAndAway
    beq ComboTrainingDecideStickAngle_DownAwayDI
    cmpwi r3, DI_None
    beq ComboTrainingDecideStickAngle_NoDI

###############
## Random DI ##
###############

# Roll RNG
ComboTrainingDecideStickAngle_RandomDI:
    li r3, 6
    branchl r12, HSD_Randi
    cmpwi r3, 0x0
    beq ComboTrainingDecideStickAngle_RandomDI_TrulyRandom
    cmpwi r3, 0x1
    beq ComboTrainingDecideStickAngle_ComboDI
    cmpwi r3, 0x2
    beq ComboTrainingDecideStickAngle_SurvivalDI
    cmpwi r3, 0x3
    beq ComboTrainingDecideStickAngle_RandomDI_SlightDI
    cmpwi r3, 0x4
    beq ComboTrainingDecideStickAngle_DownAwayDI
    cmpwi r3, 0x5
    beq ComboTrainingDecideStickAngle_NoDI

ComboTrainingDecideStickAngle_RandomDI_TrulyRandom:
    .set Combo_RandomAnalogMin, 36
    .set Combo_RandomAnalogMax, 127

    # Get X magnitude
    li r3, Combo_RandomAnalogMax - Combo_RandomAnalogMin
    branchl r12, HSD_Randi
    addi r3, r3, Combo_RandomAnalogMin
    stb r3, 0x1A8C(r29)
    # Chance to negate
    li r3, 2
    branchl r12, HSD_Randi
    cmpwi r3, 0x0
    beq 0x10
    lbz r3, 0x1A8C(r29)
    neg r3, r3
    stb r3, 0x1A8C(r29)
    # Get Y magnitude
    li r3, Combo_RandomAnalogMax - Combo_RandomAnalogMin
    branchl r12, HSD_Randi
    addi r3, r3, Combo_RandomAnalogMin
    stb r3, 0x1A8D(r29)
    # Chance to negate
    li r3, 2
    branchl r12, HSD_Randi
    cmpwi r3, 0x0
    beq 0x10
    lbz r3, 0x1A8D(r29)
    neg r3, r3
    stb r3, 0x1A8D(r29)
    b ComboTrainingDecideStickAngleExit

ComboTrainingDecideStickAngle_RandomDI_SlightDI:
    .set Combo_SlightAnalogMin, 36
    .set Combo_SlightAnalogMax, 66

    # Get X magnitude
    li r3, Combo_SlightAnalogMax - Combo_SlightAnalogMin
    branchl r12, HSD_Randi
    addi r3, r3, Combo_RandomAnalogMin
    stb r3, 0x1A8C(r29)
    # Chance to negate
    li r3, 2
    branchl r12, HSD_Randi
    cmpwi r3, 0x0
    beq 0x10
    lbz r3, 0x1A8C(r29)
    neg r3, r3
    stb r3, 0x1A8C(r29)
    # Get Y magnitude
    li r3, Combo_SlightAnalogMax - Combo_SlightAnalogMin
    branchl r12, HSD_Randi
    addi r3, r3, Combo_SlightAnalogMin
    stb r3, 0x1A8D(r29)
    # Chance to negate
    li r3, 2
    branchl r12, HSD_Randi
    cmpwi r3, 0x0
    beq 0x10
    lbz r3, 0x1A8D(r29)
    neg r3, r3
    stb r3, 0x1A8D(r29)
    b ComboTrainingDecideStickAngleExit

#######################
## Slight DI Towards ##
#######################

ComboTrainingDecideStickAngle_SlightDIInwards:
    # Get Random Stick X Input 86-105, 86-95 go in front, 96-105 go behind shiek
    li r3, 19
    branchl r12, HSD_Randi
    addi r3, r3, 86                                     # Start at 86
    lfs f1, 0x2C(r27)
    fneg f1, f1
    fctiwz f1, f1
    stfd f1, 0xF0(sp)
    lwz r4, 0xF4(sp)                                    # Facing direction as int
    mullw r3, r3, r4
    stb r3, 0x1A8C(r29)
    b ComboTrainingDecideStickAngleExit

#################
## Survival DI ##
#################

ComboTrainingDecideStickAngle_SurvivalDI:
    # Check If In Throw
    bl ComboTrainingCheckForThrowAngle
    cmpwi r3, -1
    bne ComboTrainingDecideStickAngle_SurvivalDI_UsingThrowAngle
    # Get Knockback Angle
    lwz r3, 0x1848(r29)

ComboTrainingDecideStickAngle_SurvivalDI_UsingThrowAngle:
    # Get Perpendicular Angle
    # Get Damage Direction
    cmpwi r3, 0x169                                     # Check For Sakurai Angle
    bne 0xC
    li r3, 0x2D
    li r4, 0x2D
    cmpwi r3, 90
    bge ComboTrainingDecideStickAngle_SurvivalDI_Above90
    b ComboTrainingDecideStickAngle_SurvivalDI_RightSide

ComboTrainingDecideStickAngle_SurvivalDI_Above90:
    cmpwi r3, 269
    blt ComboTrainingDecideStickAngle_SurvivalDI_LeftSide

ComboTrainingDecideStickAngle_SurvivalDI_RightSide:
    addi r3, r3, 90
    cmpwi r3, 360
    blt 0x8
    subi r3, r3, 360
    b ComboTrainingDecideStickAngle_SurvivalDI_GetXY

ComboTrainingDecideStickAngle_SurvivalDI_LeftSide:
    subi r3, r3, 90
    cmpwi r3, 0
    bgt 0x8
    addi r3, r3, 360
    b ComboTrainingDecideStickAngle_SurvivalDI_GetXY

ComboTrainingDecideStickAngle_SurvivalDI_GetXY:
    bl ComboTrainingDecideStickAngle_ConvertAngle
    stb r3, 0x1A8C(r29)
    stb r4, 0x1A8D(r29)
    bl GetDirectionInRelationToP1
    # mulli r3, r3, -1 #Negate This Value
    lbz r4, 0x1A8C(r29)
    mullw r3, r3, r4
    stb r3, 0x1A8C(r29)                                 # Point Towards Opponent
    b ComboTrainingDecideStickAngleExit

##############
## Combo DI ##
##############

ComboTrainingDecideStickAngle_ComboDI:
    # Check If In Throw
    bl ComboTrainingCheckForThrowAngle
    cmpwi r3, -1
    bne ComboTrainingDecideStickAngle_ComboDI_UsingThrowAngle
    # Get Knockback Angle
    lwz r3, 0x1848(r29)

ComboTrainingDecideStickAngle_ComboDI_UsingThrowAngle:
    mr r24, r3                                          # Backup Original Angle We're Using

    # Get Perpendicular Angle
    # Get Damage Direction
    cmpwi r3, 0x169                                     # Check For Sakurai Angle
    bne 0xC
    li r3, 0x2D
    li r4, 0x2D
    cmpwi r3, 90
    bge ComboTrainingDecideStickAngle_ComboDI_Above90
    b ComboTrainingDecideStickAngle_ComboDI_RightSide

ComboTrainingDecideStickAngle_ComboDI_Above90:
    cmpwi r3, 269
    blt ComboTrainingDecideStickAngle_ComboDI_LeftSide

ComboTrainingDecideStickAngle_ComboDI_RightSide:
    subi r3, r3, 90
    cmpwi r3, 0
    bgt 0x8
    addi r3, r3, 360
    b ComboTrainingDecideStickAngle_ComboDI_GetXY

ComboTrainingDecideStickAngle_ComboDI_LeftSide:
    addi r3, r3, 90
    cmpwi r3, 360
    blt 0x8
    subi r3, r3, 360
    b ComboTrainingDecideStickAngle_ComboDI_GetXY

ComboTrainingDecideStickAngle_ComboDI_GetXY:
    bl ComboTrainingDecideStickAngle_ConvertAngle
    stb r3, 0x1A8C(r29)
    stb r4, 0x1A8D(r29)

    # If In a Throw, Always DI The Direction Of The Angle
    lwz r3, 0x10(r29)
    cmpwi r3, 0xEF
    blt ComboTrainingDecideStickAngle_ComboDI_AdjustDirectionNoThrow
    cmpwi r3, 0xF3
    bgt ComboTrainingDecideStickAngle_ComboDI_AdjustDirectionNoThrow

ComboTrainingDecideStickAngle_ComboDI_AdjustDirectionInThrow:
    cmpwi r24, 90
    bge ComboTrainingDecideStickAngle_ComboDI_AdjustDirectionInThrow_Above90
    b ComboTrainingDecideStickAngle_ComboDI_AdjustDirectionInThrow_RightSide

ComboTrainingDecideStickAngle_ComboDI_AdjustDirectionInThrow_Above90:
    cmpwi r3, 269
    blt ComboTrainingDecideStickAngle_ComboDI_AdjustDirectionInThrow_LeftSide

ComboTrainingDecideStickAngle_ComboDI_AdjustDirectionInThrow_RightSide:
# Always Facing Direction

    li r3, 0x0
    bl IntToFloat
    lfs f2, 0x2C(r27)
    fcmpo cr0, f2, f1
    bgt ComboTrainingDecideStickAngle_ComboDI_AdjustDirectionInThrow_RightSide_Abs

ComboTrainingDecideStickAngle_ComboDI_AdjustDirectionInThrow_RightSide_AbsNeg:
    lbz r3, 0x1A8C(r29)
    extsb r3, r3
    bl IntToFloat
    fabs f1, f1
    fneg f1, f1
    b ComboTrainingDecideStickAngle_ComboDI_AdjustDirectionInThrow_RightSide_StoreX

ComboTrainingDecideStickAngle_ComboDI_AdjustDirectionInThrow_RightSide_Abs:
    lbz r3, 0x1A8C(r29)
    extsb r3, r3
    bl IntToFloat
    fabs f1, f1
    b ComboTrainingDecideStickAngle_ComboDI_AdjustDirectionInThrow_RightSide_StoreX

ComboTrainingDecideStickAngle_ComboDI_AdjustDirectionInThrow_RightSide_StoreX:
    fctiwz f1, f1
    stfd f1, 0xF0(sp)
    lwz r3, 0xF4(sp)
    stb r3, 0x1A8C(r29)
    b ComboTrainingDecideStickAngleExit

ComboTrainingDecideStickAngle_ComboDI_AdjustDirectionInThrow_LeftSide:
# Always Opposite My Facing Direction

    li r3, 0x0
    bl IntToFloat
    lfs f2, 0x2C(r27)
    fcmpo cr0, f2, f1
    bgt ComboTrainingDecideStickAngle_ComboDI_AdjustDirectionInThrow_LeftSide_AbsNeg

ComboTrainingDecideStickAngle_ComboDI_AdjustDirectionInThrow_LeftSide_Abs:
    lbz r3, 0x1A8C(r29)
    extsb r3, r3
    bl IntToFloat
    fabs f1, f1
    b ComboTrainingDecideStickAngle_ComboDI_AdjustDirectionInThrow_LeftSide_StoreX

ComboTrainingDecideStickAngle_ComboDI_AdjustDirectionInThrow_LeftSide_AbsNeg:
    lbz r3, 0x1A8C(r29)
    extsb r3, r3
    bl IntToFloat
    fabs f1, f1
    fneg f1, f1
    b ComboTrainingDecideStickAngle_ComboDI_AdjustDirectionInThrow_LeftSide_StoreX

ComboTrainingDecideStickAngle_ComboDI_AdjustDirectionInThrow_LeftSide_StoreX:
    fctiwz f1, f1
    stfd f1, 0xF0(sp)
    lwz r3, 0xF4(sp)
    stb r3, 0x1A8C(r29)
    b ComboTrainingDecideStickAngleExit

ComboTrainingDecideStickAngle_ComboDI_AdjustDirectionNoThrow:
    bl GetDirectionInRelationToP1
    # mulli r3, r3, -1 #Negate This Value
    lbz r4, 0x1A8C(r29)
    mullw r3, r3, r4
    stb r3, 0x1A8C(r29)                                 # Point Towards Opponent
    b ComboTrainingDecideStickAngleExit

######################
## Down And Away DI ##
######################

ComboTrainingDecideStickAngle_DownAwayDI:
    # Load X Value
    bl GetDirectionInRelationToP1
    # Point Away From P1
    li r4, 89
    mullw r3, r3, r4
    stb r3, 0x1A8C(r29)
    # Load Y Value
    li r3, -89
    stb r3, 0x1A8D(r29)
    # C-Stick Down
    li r3, -127
    stb r3, 0x1A8F(r29)

    b ComboTrainingDecideStickAngleExit

###########
## No DI ##
###########

ComboTrainingDecideStickAngle_NoDI:
ComboTrainingDecideStickAngleExit:
    restore
    blr

#######################################################

ComboTrainingDecideStickAngle_ConvertAngle:
    # Convert New Angle To Float
    backup

    bl IntToFloat

    # Get Pi/180
    lfs f2, -0x7510(rtoc)

    # Get Angle As Radian
    fmuls f31, f1, f2

    # Get 127 as Float
    li r3, 127
    bl IntToFloat
    fmr f30, f1

    # Convert To X and Y Components
    fmr f1, f31
    branchl r12, cos                                    # load cosine function
    fmuls f1, f1, f30                                   # Get X Component As Float
    fctiwz f1, f1
    stfd f1, 0xF0(sp)
    lwz r20, 0xF4(sp)

    fmr f1, f31
    branchl r12, sin                                    # load sine function
    fmuls f1, f1, f30                                   # Get X Component As Float
    fctiwz f1, f1
    stfd f1, 0xF0(sp)
    lwz r21, 0xF4(sp)

# Clamp Deadzones
ComboTrainingDecideStickAngle_ConvertAngle_ClampX:
    mr r3, r20
    bl IntToFloat
    fabs f3, f1
    li r3, 36
    bl IntToFloat
    fcmpo cr0, f3, f1
    bge ComboTrainingDecideStickAngle_ConvertAngle_ClampY
    li r20, 0x0

ComboTrainingDecideStickAngle_ConvertAngle_ClampY:
    mr r3, r21
    bl IntToFloat
    fabs f3, f1
    li r3, 36
    bl IntToFloat
    fcmpo cr0, f3, f1
    bge ComboTrainingDecideStickAngle_ConvertAngle_Exit
    li r21, 0x0

ComboTrainingDecideStickAngle_ConvertAngle_Exit:
    # Return X Y Stick Values
    mr r3, r20
    mr r4, r21

    restore
    blr

##############################################################

ComboTrainingCheckForThrowAngle:
    # Check If In Throw First (Must Retrieve Angle Manually)
    lwz r3, 0x10(r29)                                   # CPU AS
    cmpwi r3, 0xEF
    blt ComboTrainingCheckForThrowAngle_NoThrow
    cmpwi r3, 0xF3
    bgt ComboTrainingCheckForThrowAngle_NoThrow

    # Get Throw Angle
    addi r4, r27, 0xdf4                                 # P1 Throw Hitbox Info?
    lwz r3, 0x20(r4)                                    # Throw Angle
    b ComboTrainingCheckForThrowAngle_NoThrowExit

ComboTrainingCheckForThrowAngle_NoThrow:
    li r3, -1

ComboTrainingCheckForThrowAngle_NoThrowExit:
    blr

####################################################

ComboTrainingCheckExitStates:
    # Check For Exit States
    lwz r3, 0x10(r29)
    cmpwi r3, 0xE                                       # Wait
    beq ComboTrainingCheckExitStates_ExitState
    cmpwi r3, 0x1D                                      # Fall
    beq ComboTrainingCheckExitStates_ExitState
    cmpwi r3, 0x1B                                      # DJ
    beq ComboTrainingCheckExitStates_ExitState
    cmpwi r3, 0xFD                                      # CliffWait
    beq ComboTrainingCheckExitStates_ExitState
    cmpwi r3, 0xF5                                      # Teeter
    beq ComboTrainingCheckExitStates_ExitState
    cmpwi r3, 0x1C                                      # JumpB Aerial
    beq ComboTrainingCheckExitStates_ExitState
    cmpwi r3, 0x2A                                      # Land
    bne ComboTrainingCheckExitStates_CheckJiggsJump
    # Check If Can Interrupt Land
    lfs f1, 0x894(r29)
    lfs f2, 0x1F4(r29)
    fcmpo cr0, f1, f2
    bge ComboTrainingCheckExitStates_ExitState

ComboTrainingCheckExitStates_CheckJiggsJump:
    lwz r4, 0x4(r29)
    cmpwi r4, 0xF                                       # Check If Jiggs
    bne ComboTrainingCheckExitStates_NoExitState
    cmpwi r3, 0x155
    beq ComboTrainingCheckExitStates_ExitState

ComboTrainingCheckExitStates_NoExitState:
    li r3, 0x0
    b ComboTrainingCheckExitStates_Exit

ComboTrainingCheckExitStates_ExitState:
    li r3, 0x1
    b ComboTrainingCheckExitStates_Exit

ComboTrainingCheckExitStates_Exit:
    blr

####################################################

ComboTrainingWindowInfo:
    blrl
# amount of options, amount of options in each window

    .long 0x04060304                                    # 5 windows, DI has 7 options, SDI has 4 Options, Tech Has 5 Options
    .long 0x02020000                                    # PostHitstun has 3 options, Mash has 3 options

####################################################

ComboTrainingWindowText:
    blrl

########
## DI ##
########

    # Window Title = DI Behavior
    .string "DI Behavior"
    .align 2

    # Option 1 = Random DI
    .string "Random DI"
    .align 2

    # Option 2 = Survival DI
    .string "Survival DI"
    .align 2

    # Option 3 = Combo DI
    .string "Combo DI"
    .align 2

    # Option 4 = Slight DI Random
    .string "Slight DI Random"
    .align 2

    # Option 5 = Slight DI Towards
    .string "Slight DI Towards"
    .align 2

    # Option 6 = Down and Away DI
    .string "Down and Away DI"
    .align 2

    # Option 6 = No DI
    .string "No DI"
    .align 2

#########
## SDI ##
#########

    # SDI Behavior
    .long 0x53444920
    .long 0x42656861
    .long 0x76696f72
    .long 0x00000000

    # Option 1 = 33% Chance to SDI
    .long 0x33338193
    .long 0x20436861
    .long 0x6e636520
    .long 0x746f2053
    .long 0x44490000

    # Option 2 = 66% Chance to SDI
    .long 0x36368193
    .long 0x20436861
    .long 0x6e636520
    .long 0x746f2053
    .long 0x44490000

    # Option 3 = Always SDI
    .long 0x416c7761
    .long 0x79732053
    .long 0x44490000

    # Option 4 = No SDI
    .long 0x4e6f2053
    .long 0x44490000

#################
## Tech Option ##
#################

    # Tech Option
    .long 0x54656368
    .long 0x204f7074
    .long 0x696f6e00

    # Option 1 = Random
    .long 0x52616e64
    .long 0x6f6d0000

    # Option 2 = Missed Tech
    .long 0x4d697373
    .long 0x65642054
    .long 0x65636800

    # Option 3 = Tech In Place
    .long 0x54656368
    .long 0x20496e20
    .long 0x506c6163
    .long 0x65000000

    # Option 4 = Tech In
    .long 0x54656368
    .long 0x20496e00

    # Option 5 = Tech Away
    .long 0x54656368
    .long 0x20417761
    .long 0x79000000

#################
## Tech Option ##
#################

    # Post Hitstun Action
    .long 0x506f7374
    .long 0x20486974
    .long 0x7374756e
    .long 0x20416374
    .long 0x696f6e00

    # Airdodge/Spotdodge
    .long 0x41697264
    .long 0x6f646765
    .long 0x815e5370
    .long 0x6f74646f
    .long 0x64676500

    # Invincible
    .long 0x496e7669
    .long 0x6e636962
    .long 0x6c650000

    # Attack
    .long 0x41747461
    .long 0x636b0000

###################
## Grab Mash-Out ##
###################

    # Grab Mash-Out
    .long 0x47726162
    .long 0x204d6173
    .long 0x682d4f75
    .long 0x74000000
    .long 0x00000000

    # Random Mash
    .long 0x52616e64
    .long 0x6f6d204d
    .long 0x61736800
    .long 0x00000000
    .long 0x00000000

    # Frame Perfect
    .long 0x4672616d
    .long 0x65205065
    .long 0x72666563
    .long 0x74000000
    .long 0x00000000

    # No Mash-Out
    .long 0x4e6f204d
    .long 0x6173682d
    .long 0x4f757400
    .long 0x00000000
    .long 0x00000000

####################################################

ComboTrainingAttackList:
    blrl
    .long 0x00700466
    .long 0x02660000
    .long 0x30000303
    .long 0x04660073
    .long 0x30000152
    .long 0x00007000
    .long 0x660400FF

####################################################

ComboTrainingLoadExit:
    restore
    blr

##################################################
