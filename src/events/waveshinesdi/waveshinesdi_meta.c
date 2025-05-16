#include "../../events.h"

static const EventCharList WaveshineSDI_EventCharList = {
    .values = {
        [DOCTOR_MARIO] = 1,
        [MARIO] = 1,
        [BOWSER] = 1,
        [PEACH] = 1,
        [YOSHI] = 1,
        [DONKEY_KONG] = 1,
        [CAPTAIN_FALCON] = 1,
        [GANONDORF] = 1,
        [NESS] = 1,
        [SAMUS] = 1,
        [ZELDA] = 1,
        [LINK] = 1
    }
};

static EventMatchData WaveshineSDI_MatchData = {
    .timer = MATCH_TIMER_COUNTUP,
    .matchType = MATCH_MATCHTYPE_TIME,
    .isDisableMusic = true,
    .hideGo = true,
    .hideReady = true,
    .isCreateHUD = true,
    .isDisablePause = false,
    .timerRunOnPause = false,
    .isHidePauseHUD = true,
    .isShowLRAStart = true,
    .isCheckForLRAStart = true,
    .isShowZRetry = true,
    .isCheckForZRetry = true,
    .isShowAnalogStick = true,
    .isShowScore = false,

    .isRunStockLogic = false,
    .isDisableHit = false,
    .useKOCounter = false,
    .playerKind = -1,
    .cpuKind = 2,
    .stage = 32,
    .timerSeconds = 0,
    .timerSubSeconds = 0,
};
EventDesc WaveshineSDI = {
    .eventName = "Waveshine SDI\n",
    .eventDescription = "Use Smash DI to get out\nof Fox's waveshine!",
    .eventFile = 0,
    .jumpTableIndex = 17,
    .CSSType = SLCHRKIND_EVENT,
    .CSSList = &WaveshineSDI_EventCharList,
    .isSelectStage = false,
    .use_savestates = false,
    .disable_hazards = true,
    .force_sopo = false,
    .scoreType = SCORETYPE_KO,
    .callbackPriority = 3,
    .matchData = &WaveshineSDI_MatchData,
    .defaultOSD = 0xFFFFFFFF,
};