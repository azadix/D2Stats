#pragma once

#ifdef __cplusplus
extern "C" {
#endif

#ifndef D2UI_API
#ifdef D2STATS_UI_EXPORTS
#define D2UI_API __declspec(dllexport)
#else
#define D2UI_API __declspec(dllimport)
#endif
#endif

#define D2UI_CALL __stdcall

enum D2UiEventType {
	D2UI_EVT_NONE = 0,
	D2UI_EVT_CLOSE = 1,
	D2UI_EVT_READ = 2,
	D2UI_EVT_COMPARE = 3,
	D2UI_EVT_COMPARE_REPLACE = 4,
	D2UI_EVT_MERCENARY = 5,
	D2UI_EVT_TAB = 6,
	D2UI_EVT_OPTION = 7,
	D2UI_EVT_NOTIFY_SAVE = 8,
	D2UI_EVT_NOTIFY_RESET = 9,
	D2UI_EVT_NOTIFY_HELP = 10,
	D2UI_EVT_NOTIFY_DEFAULT = 11,
	D2UI_EVT_NOTIFY_NEW = 12,
	D2UI_EVT_NOTIFY_RENAME = 13,
	D2UI_EVT_NOTIFY_DELETE = 14,
	D2UI_EVT_NOTIFY_RULES = 15,
	D2UI_EVT_VOLUME = 16,
	D2UI_EVT_VOLUME_TEST = 17,
	D2UI_EVT_FORUM = 18,
	D2UI_EVT_COMPARE_FILTER = 19,
	D2UI_EVT_COMPARE_TOGGLE = 20,
	D2UI_EVT_COMPARE_ALL = 21,
	D2UI_EVT_COMPARE_NONE = 22,
	D2UI_EVT_SC_COMBO = 23,
	D2UI_EVT_SC_INPUT = 24,
	D2UI_EVT_SC_CHECK = 25,
	D2UI_EVT_HOTKEY = 26,
	D2UI_EVT_NOTIFIER_COLOR = 27
};

enum D2UiTab {
	D2UI_TAB_BASIC = 0,
	D2UI_TAB_PAGE1 = 1,
	D2UI_TAB_PAGE2 = 2,
	D2UI_TAB_NOTIFIER = 3,
	D2UI_TAB_SPEEDCALC = 4,
	D2UI_TAB_COMPARE = 5,
	D2UI_TAB_OPTIONS = 6,
	D2UI_TAB_ABOUT = 7
};

typedef struct D2UiEvent {
	int type;
	int i0;
	int i1;
	int i2;
	wchar_t key[64];
	wchar_t text[1024];
} D2UiEvent;

D2UI_API int D2UI_CALL D2Ui_Init(const wchar_t* title, int width, int height, const wchar_t* iconPath);
D2UI_API void D2UI_CALL D2Ui_Shutdown(void);
D2UI_API int D2UI_CALL D2Ui_Tick(void);
D2UI_API void* D2UI_CALL D2Ui_GetMainHwnd(void);
D2UI_API int D2UI_CALL D2Ui_PollEvent(D2UiEvent* out);
D2UI_API int D2UI_CALL D2Ui_GetActiveTab(void);

D2UI_API void D2UI_CALL D2Ui_OverlaySetTarget(int x, int y, int w, int h, int visible);
D2UI_API void D2UI_CALL D2Ui_Print(const wchar_t* text, unsigned int colorRgb, int timeoutMs);
D2UI_API void D2UI_CALL D2Ui_OverlayAddGap(void);
D2UI_API void D2UI_CALL D2Ui_OverlayClear(void);
D2UI_API void D2UI_CALL D2Ui_OverlayConfigure(const wchar_t* font, int fontSize, int timeoutMs, int contrast);
D2UI_API int D2UI_CALL D2Ui_OverlayIsVisible(void);

D2UI_API void D2UI_CALL D2Ui_ClearStats(void);
D2UI_API int D2UI_CALL D2Ui_AddStat(int tab, int group, int line, const wchar_t* text, const wchar_t* tooltip, int colorRgb, int header);
D2UI_API void D2UI_CALL D2Ui_UpdateStat(int index, const wchar_t* text, int colorRgb);
D2UI_API void D2UI_CALL D2Ui_SetMercenary(int checked);

D2UI_API void D2UI_CALL D2Ui_ClearOptions(void);
D2UI_API void D2UI_CALL D2Ui_AddOption(int group, const wchar_t* key, const wchar_t* type, const wchar_t* label, int intValue, const wchar_t* strValue, const wchar_t* section);
D2UI_API void D2UI_CALL D2Ui_SetNotifierColor(int index, unsigned int colorRgb);
D2UI_API void D2UI_CALL D2Ui_SetOptionChoices(const wchar_t* key, const wchar_t* pipeList);
D2UI_API void D2UI_CALL D2Ui_SetOptionInt(const wchar_t* key, int value);
D2UI_API void D2UI_CALL D2Ui_SetOptionStr(const wchar_t* key, const wchar_t* value);

D2UI_API void D2UI_CALL D2Ui_SetNotifyRules(const wchar_t* pipeList, const wchar_t* selected);
D2UI_API void D2UI_CALL D2Ui_SetNotifierText(const wchar_t* text);
D2UI_API void D2UI_CALL D2Ui_SetNotifierEdit(const wchar_t* text);
D2UI_API int D2UI_CALL D2Ui_GetNotifierText(wchar_t* buf, int cch);
D2UI_API int D2UI_CALL D2Ui_IsNotifierDirty(void);
D2UI_API int D2UI_CALL D2Ui_GetNotifyRulesSelected(wchar_t* buf, int cch);

D2UI_API void D2UI_CALL D2Ui_SetVolume(int index, int value);
D2UI_API int D2UI_CALL D2Ui_GetVolume(int index);

D2UI_API void D2UI_CALL D2Ui_SetCompareFilter(const wchar_t* filter);
D2UI_API void D2UI_CALL D2Ui_ClearCompareList(void);
D2UI_API void D2UI_CALL D2Ui_AddCompareItem(int statId, const wchar_t* name, int enabled);
D2UI_API void D2UI_CALL D2Ui_ShowDiff(int show);
D2UI_API void D2UI_CALL D2Ui_ClearDiff(void);
D2UI_API void D2UI_CALL D2Ui_AddDiffRow(int statId, const wchar_t* name, const wchar_t* oldV, const wchar_t* newV, const wchar_t* diff);

D2UI_API void D2UI_CALL D2Ui_SetSpeedCalcCombo(int which, const wchar_t* pipeList, const wchar_t* selected);
D2UI_API void D2UI_CALL D2Ui_SetSpeedCalcInput(int which, const wchar_t* value);
D2UI_API void D2UI_CALL D2Ui_SetSpeedCalcCheck(int which, int checked, int visible);
D2UI_API void D2UI_CALL D2Ui_SetSpeedCalcStatus(const wchar_t* status);
D2UI_API void D2UI_CALL D2Ui_SetSpeedCalcMorphEnabled(int enabled);
D2UI_API void D2UI_CALL D2Ui_ClearSpeedCalcTable(int table);
D2UI_API void D2UI_CALL D2Ui_AddSpeedCalcRow(int table, const wchar_t* frm, const wchar_t* value);
D2UI_API void D2UI_CALL D2Ui_SetSpeedCalcHighlight(int table, int row);

#ifdef __cplusplus
}
#endif
