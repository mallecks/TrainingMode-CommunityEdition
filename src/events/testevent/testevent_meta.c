#include "../../events.h"
#include "testevent_meta.h"

static EventMatchData TestEvent_MatchData = {
    .timer = MATCH_TIMER_HIDE,
    .matchType = MATCH_MATCHTYPE_TIME,
    .isDisableMusic = false,
    .hideGo = true,
    .hideReady = true,
    .isCreateHUD = false,
    .isDisablePause = true,
    .timerRunOnPause = false,
    .isHidePauseHUD = true,
    .isShowLRAStart = true,
    .isCheckForLRAStart = true,
    .isShowZRetry = false,
    .isCheckForZRetry = false,
    .isShowAnalogStick = true,
    .isShowScore = false,

    .isRunStockLogic = false,
    .isDisableHit = false,
    .useKOCounter = false,
    .playerKind = -1,
    .cpuKind = -1,
    .stage = -1,
    .timerSeconds = 0,
    .timerSubSeconds = 0,
};
EventDesc TestEvent = {
    .eventName = "Empty test Event\n",
    .eventDescription = "An empty event template\nfor development purposes.\n",
    .eventFile = "testevent",
    .CSSType = SLCHRKIND_EVENT,
    .isSelectStage = true,
    .use_savestates = false,
    .disable_hazards = true,
    .force_sopo = false,
    .scoreType = 0,
    .callbackPriority = 15,
    .matchData = &TestEvent_MatchData,
    .defaultOSD = 0xFFFFFFFF,
};