#define IMGUI_DEFINE_MATH_OPERATORS
#include "d2stats_ui.h"

#include <windows.h>
#include <dwmapi.h>

#include "imgui.h"
#include "imgui_impl_win32.h"
#include "imgui_impl_dx11.h"

#include "rule_editor.h"

using d2ui::RuleEditor;

#include <d3d11.h>
#include <dxgi.h>
#include <shellapi.h>

#include <algorithm>
#include <cstdio>
#include <cstring>
#include <deque>
#include <fstream>
#include <map>
#include <string>
#include <string.h>
#include <vector>

#pragma comment(lib, "d3d11.lib")
#pragma comment(lib, "dxgi.lib")
#pragma comment(lib, "d3dcompiler.lib")
#pragma comment(lib, "gdi32.lib")
#pragma comment(lib, "user32.lib")
#pragma comment(lib, "shell32.lib")

extern IMGUI_IMPL_API LRESULT ImGui_ImplWin32_WndProcHandler(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam);

namespace {

std::string WideToUtf8(const wchar_t* s) {
	if (!s || !*s)
		return {};
	int n = WideCharToMultiByte(CP_UTF8, 0, s, -1, nullptr, 0, nullptr, nullptr);
	if (n <= 1)
		return {};
	std::string out(static_cast<size_t>(n - 1), '\0');
	WideCharToMultiByte(CP_UTF8, 0, s, -1, out.data(), n, nullptr, nullptr);
	return out;
}

std::wstring Utf8ToWide(const char* s) {
	if (!s || !*s)
		return {};
	int n = MultiByteToWideChar(CP_UTF8, 0, s, -1, nullptr, 0);
	if (n <= 1)
		return {};
	std::wstring out(static_cast<size_t>(n - 1), L'\0');
	MultiByteToWideChar(CP_UTF8, 0, s, -1, out.data(), n);
	return out;
}

void CopyWide(wchar_t* dst, int cch, const wchar_t* src) {
	if (!dst || cch <= 0)
		return;
	if (!src) {
		dst[0] = 0;
		return;
	}
	wcsncpy_s(dst, static_cast<size_t>(cch), src, _TRUNCATE);
}

void CopyUtf8ToWide(wchar_t* dst, int cch, const std::string& src) {
	CopyWide(dst, cch, Utf8ToWide(src.c_str()).c_str());
}

std::vector<std::string> SplitPipe(const std::string& s) {
	std::vector<std::string> out;
	std::string cur;
	for (char c : s) {
		if (c == '|') {
			if (!cur.empty())
				out.push_back(cur);
			cur.clear();
		} else {
			cur.push_back(c);
		}
	}
	if (!cur.empty())
		out.push_back(cur);
	return out;
}

int IndexOf(const std::vector<std::string>& items, const std::string& sel) {
	for (int i = 0; i < static_cast<int>(items.size()); ++i) {
		if (items[static_cast<size_t>(i)] == sel)
			return i;
	}
	return items.empty() ? -1 : 0;
}

ImVec4 RgbToVec(int rgb) {
	if (rgb < 0)
		return ImGui::GetStyleColorVec4(ImGuiCol_Text);
	float r = ((rgb >> 16) & 0xFF) / 255.0f;
	float g = ((rgb >> 8) & 0xFF) / 255.0f;
	float b = (rgb & 0xFF) / 255.0f;
	return ImVec4(r, g, b, 1.0f);
}

ImU32 RgbToU32(unsigned rgb, int alpha = 255) {
	return IM_COL32((rgb >> 16) & 0xFF, (rgb >> 8) & 0xFF, rgb & 0xFF, alpha);
}

struct OverlayLine {
	std::string text;
	unsigned color = 0xFFFFFF;
	ULONGLONG expireAt = 0;
	bool gapAfter = false;
	bool stat = false; // smaller text than the item name
};

struct StatItem {
	int tab = 0;
	int group = 0;
	int line = 0;
	std::string text;
	std::string tooltip;
	int color = -1;
	bool header = false;
};

struct OptionItem {
	int group = 0;
	std::string key;
	std::string type;
	std::string label;
	std::string section;
	int intValue = 0;
	std::string strValue;
	std::vector<std::string> choices;
};

struct CompareItem {
	int statId = 0;
	std::string name;
	bool enabled = true;
};

struct DiffRow {
	int statId = 0;
	std::string name;
	std::string oldV;
	std::string newV;
	std::string diff;
};

struct ScTable {
	std::vector<std::pair<std::string, std::string>> rows;
	int highlight = -1;
};

struct App {
	HINSTANCE instance = nullptr;
	HWND mainHwnd = nullptr;
	HWND overlayHwnd = nullptr;
	HWND diffHwnd = nullptr;
	WNDCLASSEXW mainWc{};
	WNDCLASSEXW overlayWc{};
	WNDCLASSEXW diffWc{};
	HICON icon = nullptr;
	bool running = false;
	bool wantClose = false;
	bool overlayWantVisible = false;
	int overlayX = 0, overlayY = 0, overlayW = 0, overlayH = 0;

	ID3D11Device* device = nullptr;
	ID3D11DeviceContext* context = nullptr;
	IDXGISwapChain* swapChain = nullptr;
	ID3D11RenderTargetView* mainRtv = nullptr;
	IDXGISwapChain* diffSwap = nullptr;
	ID3D11RenderTargetView* diffRtv = nullptr;
	ID3D11Texture2D* overlayTex = nullptr;
	ID3D11RenderTargetView* overlayRtv = nullptr;
	ID3D11Texture2D* overlayStaging = nullptr;
	HDC overlayHdc = nullptr;
	HBITMAP overlayDib = nullptr;
	HBITMAP overlayOldBmp = nullptr;
	void* overlayBits = nullptr;
	int overlayBufW = 0, overlayBufH = 0;

	ImGuiContext* mainCtx = nullptr;
	ImGuiContext* overlayCtx = nullptr;
	ImGuiContext* diffCtx = nullptr;
	ImFont* overlayFont = nullptr;
	ImFont* editorFont = nullptr;
	std::string overlayFontName = "Courier New";
	int overlayFontSize = 12;
	int editorFontSize = 12;
	std::string editorFontName = "Courier New";
	int overlayTimeoutMs = 7500;
	bool overlayContrast = true;
	int overlayLineSpacing = 2;
	int overlayAtlasVersion = 0;
	bool wantMainFontRebuild = false;

	int activeTab = 0;
	bool mercenary = false;
	int capturingHotkey = -1;

	std::vector<StatItem> stats;
	std::vector<OptionItem> options;
	std::deque<D2UiEvent> events;

	std::vector<std::string> notifyRules;
	std::string notifySelected;
	std::string notifySaved;
	RuleEditor notifyEditor;
	int volumes[6] = {5, 5, 5, 5, 5, 5};
	unsigned notifierColors[12] = {
		0xFFFFFF, 0xFF0000, 0x15FF00, 0x7878F5, 0xF0CD8C, 0x9D9D9D,
		0x000000, 0xFF00FF, 0xFFBF00, 0xFFFF00, 0x008000, 0x9D00FF
	};

	std::string compareFilter;
	std::vector<CompareItem> compareItems;
	bool showDiff = false;
	std::vector<DiffRow> diffRows;

	std::vector<std::string> scCombo[5];
	std::string scSelected[5];
	std::string scInput[5];
	bool scCheck[2] = {};
	bool scCheckVisible[2] = {};
	bool scMorphEnabled = true;
	std::string scStatus;
	ScTable scTables[4];

	std::vector<OverlayLine> overlayLines;
	int theme = 0; // index into themes.ini (Light default)
	std::map<std::string, bool> sectionOpen;

	void PushEvent(int type, int i0 = 0, int i1 = 0, int i2 = 0, const char* key = nullptr, const char* text = nullptr) {
		D2UiEvent e{};
		e.type = type;
		e.i0 = i0;
		e.i1 = i1;
		e.i2 = i2;
		if (key)
			CopyUtf8ToWide(e.key, 64, key);
		if (text)
			CopyUtf8ToWide(e.text, 1024, text);
		events.push_back(e);
	}

	OptionItem* FindOption(const std::string& key) {
		for (auto& o : options) {
			if (o.key == key)
				return &o;
		}
		return nullptr;
	}
};

App g;

struct IniTheme {
	std::string name;
	std::string base = "StyleColorsLight";
	bool hasColor[ImGuiCol_COUNT]{};
	ImVec4 colors[ImGuiCol_COUNT]{};
	bool hasRounding = false;
	float rounding = 3.0f;
	bool hasFrameBorder = false;
	float frameBorder = 0.0f;
	bool hasWindowPadding = false;
	ImVec2 windowPadding{};
	bool hasFramePadding = false;
	ImVec2 framePadding{};
	bool hasItemSpacing = false;
	ImVec2 itemSpacing{};
	bool hasItemInnerSpacing = false;
	ImVec2 itemInnerSpacing{};
	bool hasIndentSpacing = false;
	float indentSpacing = 0.0f;
	bool hasScrollbarSize = false;
	float scrollbarSize = 0.0f;
	bool hasGrabMinSize = false;
	float grabMinSize = 0.0f;
	bool hasWindowBorderSize = false;
	float windowBorderSize = 0.0f;
	bool hasPopupBorderSize = false;
	float popupBorderSize = 0.0f;
};

std::vector<IniTheme> g_iniThemes;
std::vector<std::string> g_themeNames;
std::vector<const char*> g_themeNamePtrs;

const unsigned kDefaultNotifierColors[12] = {
	0xFFFFFF, 0xFF0000, 0x15FF00, 0x7878F5, 0xF0CD8C, 0x9D9D9D,
	0x000000, 0xFF00FF, 0xFFBF00, 0xFFFF00, 0x008000, 0x9D00FF
};

const char* kNotifierColorNames[12] = {
	"White", "Red", "Lime", "Blue", "Gold", "Grey",
	"Black", "Pink", "Orange", "Yellow", "Green", "Purple"
};

unsigned PackRgb(const float col[3]) {
	int r = static_cast<int>(col[0] * 255.0f + 0.5f);
	int g = static_cast<int>(col[1] * 255.0f + 0.5f);
	int b = static_cast<int>(col[2] * 255.0f + 0.5f);
	if (r < 0) r = 0;
	if (g < 0) g = 0;
	if (b < 0) b = 0;
	if (r > 255) r = 255;
	if (g > 255) g = 255;
	if (b > 255) b = 255;
	return (static_cast<unsigned>(r) << 16) | (static_cast<unsigned>(g) << 8) | static_cast<unsigned>(b);
}

void UnpackRgb(unsigned rgb, float col[3]) {
	col[0] = ((rgb >> 16) & 0xFF) / 255.0f;
	col[1] = ((rgb >> 8) & 0xFF) / 255.0f;
	col[2] = (rgb & 0xFF) / 255.0f;
}

std::wstring ModuleDirPath() {
	wchar_t path[MAX_PATH]{};
	HMODULE mod = nullptr;
	GetModuleHandleExW(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS | GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
		reinterpret_cast<LPCWSTR>(&ModuleDirPath), &mod);
	GetModuleFileNameW(mod, path, MAX_PATH);
	std::wstring p(path);
	size_t slash = p.find_last_of(L"\\/");
	if (slash != std::wstring::npos)
		p.resize(slash + 1);
	return p;
}

std::wstring UiIniPath() {
	return ModuleDirPath() + L"D2Stats.exe.ini";
}

std::wstring ThemesIniPath() {
	return ModuleDirPath() + L"themes.ini";
}

std::string ThemesIniPathUtf8Fallback() {
	return WideToUtf8(ThemesIniPath().c_str());
}

void RebuildThemeNamePtrs() {
	g_themeNamePtrs.clear();
	g_themeNamePtrs.reserve(g_themeNames.size());
	for (const std::string& n : g_themeNames)
		g_themeNamePtrs.push_back(n.c_str());
}

int FindImGuiColByName(const std::string& name) {
	for (int i = 0; i < ImGuiCol_COUNT; ++i) {
		if (name == ImGui::GetStyleColorName(i))
			return i;
	}
	if (name == "TabActive")
		return ImGuiCol_TabSelected;
	if (name == "TabUnfocused")
		return ImGuiCol_TabDimmed;
	if (name == "TabUnfocusedActive")
		return ImGuiCol_TabDimmedSelected;
	return -1;
}

bool ParseFloatList(const std::string& s, float* out, int count) {
	size_t pos = 0;
	for (int i = 0; i < count; ++i) {
		while (pos < s.size() && (s[pos] == ' ' || s[pos] == '\t'))
			++pos;
		if (pos >= s.size())
			return false;
		char* end = nullptr;
		out[i] = strtof(s.c_str() + pos, &end);
		if (end == s.c_str() + pos)
			return false;
		pos = static_cast<size_t>(end - s.c_str());
		while (pos < s.size() && (s[pos] == ' ' || s[pos] == '\t' || s[pos] == ','))
			++pos;
	}
	return true;
}

void LoadThemesFromIni() {
	g_iniThemes.clear();
	g_themeNames.clear();

	std::ifstream in(ThemesIniPath().c_str());
	if (!in)
		in.open(ThemesIniPathUtf8Fallback().c_str());
	if (!in) {
		RebuildThemeNamePtrs();
		return;
	}

	IniTheme* cur = nullptr;
	std::string line;
	while (std::getline(in, line)) {
		while (!line.empty() && (line.back() == '\r' || line.back() == ' ' || line.back() == '\t'))
			line.pop_back();
		size_t start = 0;
		while (start < line.size() && (line[start] == ' ' || line[start] == '\t'))
			++start;
		if (start > 0)
			line = line.substr(start);
		if (line.empty() || line[0] == ';' || line[0] == '#')
			continue;
		if (line.front() == '[' && line.back() == ']') {
			IniTheme theme;
			theme.name = line.substr(1, line.size() - 2);
			g_iniThemes.push_back(std::move(theme));
			cur = &g_iniThemes.back();
			g_themeNames.push_back(cur->name);
			continue;
		}
		if (!cur)
			continue;
		size_t eq = line.find('=');
		if (eq == std::string::npos)
			continue;
		std::string key = line.substr(0, eq);
		std::string val = line.substr(eq + 1);
		while (!key.empty() && (key.back() == ' ' || key.back() == '\t'))
			key.pop_back();
		while (!val.empty() && (val.front() == ' ' || val.front() == '\t'))
			val.erase(val.begin());

		if (key == "Rounding") {
			cur->hasRounding = true;
			cur->rounding = strtof(val.c_str(), nullptr);
		} else if (key == "FrameBorder") {
			cur->hasFrameBorder = true;
			cur->frameBorder = strtof(val.c_str(), nullptr);
		} else if (key == "WindowPadding") {
			float v[2]{};
			if (ParseFloatList(val, v, 2)) {
				cur->hasWindowPadding = true;
				cur->windowPadding = ImVec2(v[0], v[1]);
			}
		} else if (key == "FramePadding") {
			float v[2]{};
			if (ParseFloatList(val, v, 2)) {
				cur->hasFramePadding = true;
				cur->framePadding = ImVec2(v[0], v[1]);
			}
		} else if (key == "ItemSpacing") {
			float v[2]{};
			if (ParseFloatList(val, v, 2)) {
				cur->hasItemSpacing = true;
				cur->itemSpacing = ImVec2(v[0], v[1]);
			}
		} else if (key == "ItemInnerSpacing") {
			float v[2]{};
			if (ParseFloatList(val, v, 2)) {
				cur->hasItemInnerSpacing = true;
				cur->itemInnerSpacing = ImVec2(v[0], v[1]);
			}
		} else if (key == "IndentSpacing") {
			cur->hasIndentSpacing = true;
			cur->indentSpacing = strtof(val.c_str(), nullptr);
		} else if (key == "ScrollbarSize") {
			cur->hasScrollbarSize = true;
			cur->scrollbarSize = strtof(val.c_str(), nullptr);
		} else if (key == "GrabMinSize") {
			cur->hasGrabMinSize = true;
			cur->grabMinSize = strtof(val.c_str(), nullptr);
		} else if (key == "WindowBorderSize") {
			cur->hasWindowBorderSize = true;
			cur->windowBorderSize = strtof(val.c_str(), nullptr);
		} else if (key == "PopupBorderSize") {
			cur->hasPopupBorderSize = true;
			cur->popupBorderSize = strtof(val.c_str(), nullptr);
		} else if (key == "Base") {
			cur->base = val;
		} else {
			int col = FindImGuiColByName(key);
			if (col >= 0) {
				float v[4]{};
				if (ParseFloatList(val, v, 4)) {
					cur->hasColor[col] = true;
					cur->colors[col] = ImVec4(v[0], v[1], v[2], v[3]);
				}
			}
		}
	}

	RebuildThemeNamePtrs();
}

void ApplySharedLayoutMetrics() {
	ImGuiStyle& style = ImGui::GetStyle();
	const float r = 8.0f;
	style.WindowRounding = r;
	style.ChildRounding = r;
	style.FrameRounding = r * 0.75f;
	style.PopupRounding = r * 0.75f;
	style.ScrollbarRounding = 9.0f;
	style.GrabRounding = r * 0.75f;
	style.TabRounding = r * 0.75f;
	style.FramePadding = ImVec2(5, 2);
	style.ItemSpacing = ImVec2(6, 2);
	style.ItemInnerSpacing = ImVec2(4, 2);
	style.CellPadding = ImVec2(4, 1);
	style.ScrollbarSize = 14.0f;
	style.FrameBorderSize = 1.0f;
}

void ApplyFallbackLightThemeStyle() {
	ImGui::StyleColorsLight();
	ApplySharedLayoutMetrics();
	ImGui::GetStyle().Colors[ImGuiCol_Border] = ImVec4(0.45f, 0.45f, 0.50f, 1.0f);
}

void ApplyIniThemeStyle(const IniTheme& theme) {
	if (theme.base == "StyleColorsLight")
		ImGui::StyleColorsLight();
	else
		ImGui::StyleColorsDark();

	ApplySharedLayoutMetrics();

	ImGuiStyle& style = ImGui::GetStyle();
	for (int i = 0; i < ImGuiCol_COUNT; ++i) {
		if (theme.hasColor[i])
			style.Colors[i] = theme.colors[i];
	}
	// Keep selected-tab overline on the theme accent (CheckMark), not StyleColorsDark blue.
	if (!theme.hasColor[ImGuiCol_TabSelectedOverline])
		style.Colors[ImGuiCol_TabSelectedOverline] = style.Colors[ImGuiCol_CheckMark];
	if (!theme.hasColor[ImGuiCol_TabDimmedSelectedOverline]) {
		ImVec4 dim = style.Colors[ImGuiCol_CheckMark];
		dim.w *= 0.80f;
		style.Colors[ImGuiCol_TabDimmedSelectedOverline] = dim;
	}
}

void ApplyThemeToCurrentContext() {
	if (g.theme < 0 || g.theme >= static_cast<int>(g_iniThemes.size())) {
		ApplyFallbackLightThemeStyle();
		return;
	}
	ApplyIniThemeStyle(g_iniThemes[static_cast<size_t>(g.theme)]);
}

// ---------------------------------------------------------------------------
// Window frame
// ---------------------------------------------------------------------------

// The title bar and the outer border are drawn by DWM, not by ImGui, so they can
// only follow the theme through DwmSetWindowAttribute. Numbers instead of the
// DWMWA_* names keep this compiling on SDKs that predate Windows 11.
void ApplyWindowFrameColors(HWND hwnd) {
	if (!hwnd || !g.mainCtx)
		return;

	ImGuiContext* prev = ImGui::GetCurrentContext();
	ImGui::SetCurrentContext(g.mainCtx);
	const ImVec4 bg = ImGui::GetStyleColorVec4(ImGuiCol_WindowBg);
	const ImVec4 border = ImGui::GetStyleColorVec4(ImGuiCol_Border);
	const ImVec4 text = ImGui::GetStyleColorVec4(ImGuiCol_Text);
	if (prev)
		ImGui::SetCurrentContext(prev);

	auto colorRef = [](const ImVec4& c) {
		auto channel = [](float v) {
			const float clamped = v < 0.0f ? 0.0f : (v > 1.0f ? 1.0f : v);
			return static_cast<DWORD>(clamped * 255.0f + 0.5f);
		};
		return RGB(channel(c.x), channel(c.y), channel(c.z));
	};

	const BOOL dark = (text.x + text.y + text.z) > 1.5f ? TRUE : FALSE;
	const COLORREF caption = colorRef(bg);
	const COLORREF frame = colorRef(border);
	const COLORREF titleText = colorRef(text);

	DwmSetWindowAttribute(hwnd, 20 /* DWMWA_USE_IMMERSIVE_DARK_MODE */, &dark, sizeof(dark));
	DwmSetWindowAttribute(hwnd, 35 /* DWMWA_CAPTION_COLOR */, &caption, sizeof(caption));
	DwmSetWindowAttribute(hwnd, 34 /* DWMWA_BORDER_COLOR */, &frame, sizeof(frame));
	DwmSetWindowAttribute(hwnd, 36 /* DWMWA_TEXT_COLOR */, &titleText, sizeof(titleText));

}

void ApplyThemeAllContexts() {	ImGuiContext* prev = ImGui::GetCurrentContext();
	if (g.mainCtx) {
		ImGui::SetCurrentContext(g.mainCtx);
		ApplyThemeToCurrentContext();
	}
	if (g.overlayCtx) {
		ImGui::SetCurrentContext(g.overlayCtx);
		ApplyThemeToCurrentContext();
	}
	if (g.diffCtx) {
		ImGui::SetCurrentContext(g.diffCtx);
		ApplyThemeToCurrentContext();
	}
	if (prev)
		ImGui::SetCurrentContext(prev);

	ApplyWindowFrameColors(g.mainHwnd);
	ApplyWindowFrameColors(g.diffHwnd);
}

int FindThemeIndexByName(const char* name) {
	for (int i = 0; i < static_cast<int>(g_themeNames.size()); ++i) {
		if (_stricmp(g_themeNames[static_cast<size_t>(i)].c_str(), name) == 0)
			return i;
	}
	return -1;
}

void LoadTheme() {
	if (g_themeNames.empty())
		LoadThemesFromIni();
	wchar_t buf[64]{};
	GetPrivateProfileStringW(L"UI", L"Theme", L"Light", buf, 64, UiIniPath().c_str());
	g.theme = FindThemeIndexByName("Light");
	if (g.theme < 0)
		g.theme = 0;
	const std::string saved = WideToUtf8(buf);
	const int savedIndex = FindThemeIndexByName(saved.c_str());
	if (savedIndex >= 0)
		g.theme = savedIndex;
}

void SaveTheme() {
	if (g.theme < 0 || g.theme >= static_cast<int>(g_themeNames.size()))
		g.theme = 0;
	WritePrivateProfileStringW(L"UI", L"Theme", Utf8ToWide(g_themeNames[static_cast<size_t>(g.theme)].c_str()).c_str(), UiIniPath().c_str());
}

const char* kOptionsSectionNames[] = {
	"General", "Overlay", "Notification colors", "Notifier editor", "Sounds", "Hotkeys"
};

std::wstring SectionIniKey(const char* name) {
	return std::wstring(L"Section.") + Utf8ToWide(name);
}

// Only General starts expanded; everything else starts collapsed.
bool SectionDefaultOpen(const char* name) {
	return strcmp(name, "General") == 0;
}

bool GetSectionOpen(const char* name) {
	auto it = g.sectionOpen.find(name);
	if (it != g.sectionOpen.end())
		return it->second;
	return SectionDefaultOpen(name);
}

void SaveSectionOpen(const char* name, bool open) {
	g.sectionOpen[name] = open;
	WritePrivateProfileStringW(L"UI", SectionIniKey(name).c_str(), open ? L"1" : L"0", UiIniPath().c_str());
}

void LoadSectionOpen() {
	std::wstring ini = UiIniPath();
	// The groups were reorganised (Notifier split into Overlay and Notifier editor),
	// so states saved by an older build are dropped once.
	wchar_t version[8]{};
	GetPrivateProfileStringW(L"UI", L"OptionsSectionsVersion", L"0", version, 8, ini.c_str());
	const bool reset = _wtoi(version) < 2;
	for (const char* name : kOptionsSectionNames) {
		const bool defaultOpen = SectionDefaultOpen(name);
		wchar_t buf[8]{};
		GetPrivateProfileStringW(L"UI", SectionIniKey(name).c_str(), defaultOpen ? L"1" : L"0", buf, 8, ini.c_str());
		const bool open = reset ? defaultOpen : (buf[0] != L'0');
		g.sectionOpen[name] = open;
		if (reset)
			WritePrivateProfileStringW(L"UI", SectionIniKey(name).c_str(), open ? L"1" : L"0", ini.c_str());
	}
	if (reset)
		WritePrivateProfileStringW(L"UI", L"OptionsSectionsVersion", L"2", ini.c_str());
}

bool OptionsSectionHeader(const char* name) {
	bool open = GetSectionOpen(name);
	ImGui::SetNextItemOpen(open);
	bool now = ImGui::CollapsingHeader(name);
	if (now != open)
		SaveSectionOpen(name, now);
	return now;
}

void DrawThemeSwitcher() {
	if (g_themeNamePtrs.empty())
		LoadThemesFromIni();
	int t = g.theme;
	ImGui::SetNextItemWidth(220);
	if (!g_themeNamePtrs.empty() && ImGui::Combo("Theme", &t, g_themeNamePtrs.data(), static_cast<int>(g_themeNamePtrs.size()))) {
		g.theme = t;
		ApplyThemeAllContexts();
		SaveTheme();
	}
}

void CreateMainRenderTarget() {
	ID3D11Texture2D* back = nullptr;
	g.swapChain->GetBuffer(0, IID_PPV_ARGS(&back));
	if (back) {
		g.device->CreateRenderTargetView(back, nullptr, &g.mainRtv);
		back->Release();
	}
}

void CleanupMainRenderTarget() {
	if (g.mainRtv) {
		g.mainRtv->Release();
		g.mainRtv = nullptr;
	}
}

void CreateDiffRenderTarget() {
	if (!g.diffSwap)
		return;
	ID3D11Texture2D* back = nullptr;
	g.diffSwap->GetBuffer(0, IID_PPV_ARGS(&back));
	if (back) {
		g.device->CreateRenderTargetView(back, nullptr, &g.diffRtv);
		back->Release();
	}
}

void CleanupDiffRenderTarget() {
	if (g.diffRtv) {
		g.diffRtv->Release();
		g.diffRtv = nullptr;
	}
}

IDXGIFactory* GetDxgiFactory() {
	IDXGIDevice* dxgiDev = nullptr;
	if (FAILED(g.device->QueryInterface(IID_PPV_ARGS(&dxgiDev))) || !dxgiDev)
		return nullptr;
	IDXGIAdapter* adapter = nullptr;
	dxgiDev->GetAdapter(&adapter);
	dxgiDev->Release();
	if (!adapter)
		return nullptr;
	IDXGIFactory* factory = nullptr;
	adapter->GetParent(IID_PPV_ARGS(&factory));
	adapter->Release();
	return factory;
}

bool CreateDiffSwapChain() {
	if (!g.diffHwnd || !g.device)
		return false;
	CleanupDiffRenderTarget();
	if (g.diffSwap) {
		g.diffSwap->Release();
		g.diffSwap = nullptr;
	}
	IDXGIFactory* factory = GetDxgiFactory();
	if (!factory)
		return false;
	RECT rc{};
	GetClientRect(g.diffHwnd, &rc);
	int w = rc.right - rc.left;
	int h = rc.bottom - rc.top;
	if (w < 1)
		w = 1;
	if (h < 1)
		h = 1;
	DXGI_SWAP_CHAIN_DESC sd{};
	sd.BufferCount = 2;
	sd.BufferDesc.Width = static_cast<UINT>(w);
	sd.BufferDesc.Height = static_cast<UINT>(h);
	sd.BufferDesc.Format = DXGI_FORMAT_R8G8B8A8_UNORM;
	sd.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;
	sd.OutputWindow = g.diffHwnd;
	sd.SampleDesc.Count = 1;
	sd.Windowed = TRUE;
	sd.SwapEffect = DXGI_SWAP_EFFECT_DISCARD;
	HRESULT hr = factory->CreateSwapChain(g.device, &sd, &g.diffSwap);
	factory->Release();
	if (FAILED(hr) || !g.diffSwap)
		return false;
	CreateDiffRenderTarget();
	return g.diffRtv != nullptr;
}

void CleanupOverlayBuffers() {
	if (g.overlayRtv) {
		g.overlayRtv->Release();
		g.overlayRtv = nullptr;
	}
	if (g.overlayTex) {
		g.overlayTex->Release();
		g.overlayTex = nullptr;
	}
	if (g.overlayStaging) {
		g.overlayStaging->Release();
		g.overlayStaging = nullptr;
	}
	if (g.overlayHdc && g.overlayOldBmp) {
		SelectObject(g.overlayHdc, g.overlayOldBmp);
		g.overlayOldBmp = nullptr;
	}
	if (g.overlayDib) {
		DeleteObject(g.overlayDib);
		g.overlayDib = nullptr;
		g.overlayBits = nullptr;
	}
	if (g.overlayHdc) {
		DeleteDC(g.overlayHdc);
		g.overlayHdc = nullptr;
	}
	g.overlayBufW = g.overlayBufH = 0;
}

bool EnsureOverlayBuffers(int w, int h) {
	if (w < 1)
		w = 1;
	if (h < 1)
		h = 1;
	if (g.overlayTex && g.overlayBufW == w && g.overlayBufH == h)
		return true;
	CleanupOverlayBuffers();

	D3D11_TEXTURE2D_DESC td{};
	td.Width = static_cast<UINT>(w);
	td.Height = static_cast<UINT>(h);
	td.MipLevels = 1;
	td.ArraySize = 1;
	td.Format = DXGI_FORMAT_R8G8B8A8_UNORM;
	td.SampleDesc.Count = 1;
	td.Usage = D3D11_USAGE_DEFAULT;
	td.BindFlags = D3D11_BIND_RENDER_TARGET;
	if (FAILED(g.device->CreateTexture2D(&td, nullptr, &g.overlayTex)))
		return false;
	if (FAILED(g.device->CreateRenderTargetView(g.overlayTex, nullptr, &g.overlayRtv)))
		return false;

	td.Usage = D3D11_USAGE_STAGING;
	td.BindFlags = 0;
	td.CPUAccessFlags = D3D11_CPU_ACCESS_READ;
	if (FAILED(g.device->CreateTexture2D(&td, nullptr, &g.overlayStaging)))
		return false;

	BITMAPINFO bmi{};
	bmi.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
	bmi.bmiHeader.biWidth = w;
	bmi.bmiHeader.biHeight = -h;
	bmi.bmiHeader.biPlanes = 1;
	bmi.bmiHeader.biBitCount = 32;
	bmi.bmiHeader.biCompression = BI_RGB;
	g.overlayHdc = CreateCompatibleDC(nullptr);
	g.overlayDib = CreateDIBSection(g.overlayHdc, &bmi, DIB_RGB_COLORS, &g.overlayBits, nullptr, 0);
	if (!g.overlayHdc || !g.overlayDib)
		return false;
	g.overlayOldBmp = static_cast<HBITMAP>(SelectObject(g.overlayHdc, g.overlayDib));
	g.overlayBufW = w;
	g.overlayBufH = h;
	return true;
}

bool CreateDevice(HWND hwnd) {
	DXGI_SWAP_CHAIN_DESC sd{};
	sd.BufferCount = 2;
	sd.BufferDesc.Format = DXGI_FORMAT_R8G8B8A8_UNORM;
	sd.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;
	sd.OutputWindow = hwnd;
	sd.SampleDesc.Count = 1;
	sd.Windowed = TRUE;
	sd.SwapEffect = DXGI_SWAP_EFFECT_DISCARD;

	UINT flags = 0;
	D3D_FEATURE_LEVEL fl;
	const D3D_FEATURE_LEVEL levels[2] = {D3D_FEATURE_LEVEL_11_0, D3D_FEATURE_LEVEL_10_0};
	HRESULT hr = D3D11CreateDeviceAndSwapChain(nullptr, D3D_DRIVER_TYPE_HARDWARE, nullptr, flags, levels, 2,
		D3D11_SDK_VERSION, &sd, &g.swapChain, &g.device, &fl, &g.context);
	if (FAILED(hr)) {
		hr = D3D11CreateDeviceAndSwapChain(nullptr, D3D_DRIVER_TYPE_WARP, nullptr, flags, levels, 2,
			D3D11_SDK_VERSION, &sd, &g.swapChain, &g.device, &fl, &g.context);
	}
	if (FAILED(hr))
		return false;
	CreateMainRenderTarget();
	return true;
}

void DestroyDevice() {
	CleanupOverlayBuffers();
	CleanupDiffRenderTarget();
	CleanupMainRenderTarget();
	if (g.diffSwap) {
		g.diffSwap->Release();
		g.diffSwap = nullptr;
	}
	if (g.swapChain) {
		g.swapChain->Release();
		g.swapChain = nullptr;
	}
	if (g.context) {
		g.context->Release();
		g.context = nullptr;
	}
	if (g.device) {
		g.device->Release();
		g.device = nullptr;
	}
}

std::wstring WindowsFontPath(const wchar_t* fileName) {
	wchar_t windir[MAX_PATH];
	GetWindowsDirectoryW(windir, MAX_PATH);
	std::wstring path = std::wstring(windir) + L"\\Fonts\\" + fileName;
	if (GetFileAttributesW(path.c_str()) == INVALID_FILE_ATTRIBUTES)
		return {};
	return path;
}

bool FontRegNameMatches(const std::wstring& name, const std::wstring& want) {
	if (name == want)
		return true;
	return name.rfind(want + L" (", 0) == 0;
}

std::wstring FindFontFile(const std::string& face) {
	if (face.empty())
		return {};
	HKEY key;
	if (RegOpenKeyExW(HKEY_LOCAL_MACHINE, L"SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Fonts", 0, KEY_READ, &key) != ERROR_SUCCESS)
		return {};
	std::wstring want = Utf8ToWide(face.c_str());
	std::wstring found;
	for (DWORD i = 0;; ++i) {
		wchar_t name[256];
		wchar_t data[MAX_PATH];
		DWORD nlen = 256, dlen = sizeof(data), type = 0;
		LONG r = RegEnumValueW(key, i, name, &nlen, nullptr, &type, reinterpret_cast<LPBYTE>(data), &dlen);
		if (r == ERROR_NO_MORE_ITEMS)
			break;
		if (r != ERROR_SUCCESS || type != REG_SZ)
			continue;
		if (!FontRegNameMatches(name, want))
			continue;
		std::wstring path(data);
		if (path.find(L'\\') == std::wstring::npos) {
			wchar_t windir[MAX_PATH];
			GetWindowsDirectoryW(windir, MAX_PATH);
			path = std::wstring(windir) + L"\\Fonts\\" + path;
		}
		found = path;
		break;
	}
	RegCloseKey(key);
	return found;
}

std::wstring ResolveFaceFile(const std::string& face) {
	std::wstring path = FindFontFile(face);
	if (!path.empty())
		return path;
	if (_stricmp(face.c_str(), "Courier New") == 0)
		return WindowsFontPath(L"cour.ttf");
	if (_stricmp(face.c_str(), "Consolas") == 0)
		return WindowsFontPath(L"consola.ttf");
	if (_stricmp(face.c_str(), "Lucida Console") == 0)
		return WindowsFontPath(L"lucon.ttf");
	if (_stricmp(face.c_str(), "Cascadia Mono") == 0)
		return WindowsFontPath(L"CascadiaMono.ttf");
	if (_stricmp(face.c_str(), "Segoe UI") == 0)
		return WindowsFontPath(L"segoeui.ttf");
	return {};
}

float OverlayFontPixels() {
	int pt = std::max(8, g.overlayFontSize);
	HDC dc = GetDC(nullptr);
	int dpi = dc ? GetDeviceCaps(dc, LOGPIXELSY) : 96;
	if (dc)
		ReleaseDC(nullptr, dc);
	if (dpi < 1)
		dpi = 96;
	return pt * static_cast<float>(dpi) / 72.0f;
}

ImFont* AddFaceFont(ImGuiIO& io, const std::string& face, float pixelSize) {
	std::wstring path = ResolveFaceFile(face);
	// The registry (and the known file names) can name a font that is not actually
	// installed - a bare Wine prefix has almost nothing. Dear ImGui asserts when
	// AddFontFromFileTTF cannot read the file, so check it first.
	if (path.empty() || GetFileAttributesW(path.c_str()) == INVALID_FILE_ATTRIBUTES)
		return nullptr;
	ImFontConfig cfg;
	cfg.OversampleH = 2;
	cfg.OversampleV = 2;
	cfg.PixelSnapH = true;
	return io.Fonts->AddFontFromFileTTF(WideToUtf8(path.c_str()).c_str(), pixelSize, &cfg);
}

// The notifier editor has its own size setting, independent of the overlay.
float EditorFontPixels() {
	int pt = std::max(6, g.editorFontSize);
	HDC dc = GetDC(nullptr);
	int dpi = dc ? GetDeviceCaps(dc, LOGPIXELSY) : 96;
	if (dc)
		ReleaseDC(nullptr, dc);
	if (dpi < 1)
		dpi = 96;
	return pt * static_cast<float>(dpi) / 72.0f;
}

void LoadUiFont(ImGuiContext* ctx) {
	if (!ctx)
		return;
	ImGui::SetCurrentContext(ctx);
	ImGuiIO& io = ImGui::GetIO();
	io.Fonts->Clear();
	ImFont* font = AddFaceFont(io, "Segoe UI", 17.0f);
	if (!font)
		font = AddFaceFont(io, "Tahoma", 16.0f);
	if (!font)
		font = AddFaceFont(io, "Consolas", 16.0f);
	if (!font)
		io.Fonts->AddFontDefault();

	if (ctx == g.mainCtx) {
		// The rule editor has its own face and size settings.
		const float editorPixels = EditorFontPixels();
		g.editorFont = AddFaceFont(io, g.editorFontName, editorPixels);
		if (!g.editorFont)
			g.editorFont = AddFaceFont(io, "Courier New", editorPixels);
		if (!g.editorFont)
			g.editorFont = AddFaceFont(io, "Consolas", 13.0f);
		if (!g.editorFont)
			g.editorFont = AddFaceFont(io, "Cascadia Mono", 13.0f);
		if (!g.editorFont)
			g.editorFont = font;
	}

	// 1.92+ builds and uploads the atlas in the backend (RendererHasTextures).
}

// Rebuilds the settings-window atlas after the overlay font changed. The editor
// is the only widget that uses the second font, so the UI font is re-added too.
void RebuildMainFonts() {
	if (!g.mainCtx)
		return;
	ImGuiContext* prev = ImGui::GetCurrentContext();
	ImGui::SetCurrentContext(g.mainCtx);
	LoadUiFont(g.mainCtx);
	ImGui_ImplDX11_InvalidateDeviceObjects();
	ImGui_ImplDX11_CreateDeviceObjects();
	if (prev)
		ImGui::SetCurrentContext(prev);
}

void RebuildOverlayFont() {
	if (!g.overlayCtx)
		return;
	ImGuiContext* prev = ImGui::GetCurrentContext();
	ImGui::SetCurrentContext(g.overlayCtx);
	ImGuiIO& io = ImGui::GetIO();
	io.Fonts->Clear();
	g.overlayFont = AddFaceFont(io, g.overlayFontName, OverlayFontPixels());
	if (!g.overlayFont)
		g.overlayFont = AddFaceFont(io, "Courier New", OverlayFontPixels());
	if (!g.overlayFont)
		g.overlayFont = io.Fonts->AddFontDefault();
	// 1.92+ builds and uploads the atlas in the backend (RendererHasTextures).
	ImGui_ImplDX11_InvalidateDeviceObjects();
	ImGui_ImplDX11_CreateDeviceObjects();
	g.overlayAtlasVersion++;
	if (prev)
		ImGui::SetCurrentContext(prev);
}

std::string HotkeyLabel(int code) {
	int vk = code & 0xFF;
	int mod = (code >> 8) & 0xFF;
	if (vk == 0)
		return "<Disabled>";
	std::string s;
	if (mod & 0x01)
		s += "Shift+";
	if (mod & 0x02)
		s += "Ctrl+";
	if (mod & 0x04)
		s += "Alt+";
	if (mod & 0x08)
		s += "Win+";
	UINT scan = MapVirtualKeyW(static_cast<UINT>(vk), MAPVK_VK_TO_VSC);
	LONG lparam = static_cast<LONG>(scan << 16);
	if (vk == VK_RMENU || vk == VK_RCONTROL || vk == VK_INSERT || vk == VK_DELETE || vk == VK_HOME || vk == VK_END ||
		vk == VK_PRIOR || vk == VK_NEXT || vk == VK_LEFT || vk == VK_RIGHT || vk == VK_UP || vk == VK_DOWN || vk == VK_NUMLOCK ||
		vk == VK_DIVIDE)
		lparam |= 1 << 24;
	wchar_t name[64]{};
	if (GetKeyNameTextW(lparam, name, 64) > 0)
		s += WideToUtf8(name);
	else {
		char buf[16];
		sprintf_s(buf, "VK_%02X", vk);
		s += buf;
	}
	return s;
}

int CaptureHotkey() {
	bool shift = (GetAsyncKeyState(VK_SHIFT) & 0x8000) != 0;
	bool ctrl = (GetAsyncKeyState(VK_CONTROL) & 0x8000) != 0;
	bool alt = (GetAsyncKeyState(VK_MENU) & 0x8000) != 0;
	bool win = (GetAsyncKeyState(VK_LWIN) & 0x8000) != 0 || (GetAsyncKeyState(VK_RWIN) & 0x8000) != 0;
	for (int vk = 1; vk < 256; ++vk) {
		if (vk == VK_SHIFT || vk == VK_CONTROL || vk == VK_MENU || vk == VK_LSHIFT || vk == VK_RSHIFT || vk == VK_LCONTROL ||
			vk == VK_RCONTROL || vk == VK_LMENU || vk == VK_RMENU || vk == VK_LWIN || vk == VK_RWIN || vk == VK_CAPITAL ||
			vk == VK_NUMLOCK || vk == VK_SCROLL)
			continue;
		if (vk <= 6)
			continue;
		if ((GetAsyncKeyState(vk) & 0x8000) == 0)
			continue;
		if (vk == VK_ESCAPE)
			return 0;
		int mod = 0;
		if (shift)
			mod |= 0x01;
		if (ctrl)
			mod |= 0x02;
		if (alt)
			mod |= 0x04;
		if (win)
			mod |= 0x08;
		return (mod << 8) | vk;
	}
	return -1;
}

LRESULT CALLBACK MainWndProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam) {
	if (g.mainCtx) {
		ImGui::SetCurrentContext(g.mainCtx);
		if (ImGui_ImplWin32_WndProcHandler(hWnd, msg, wParam, lParam))
			return true;
	}
	switch (msg) {
	case WM_ACTIVATE:
		// DWM only applies the caption/border colours once the window is activated,
		// so refresh them whenever it gains focus.
		if (LOWORD(wParam) != WA_INACTIVE)
			ApplyWindowFrameColors(hWnd);
		return 0;
	case WM_SIZE:
		if (g.device && wParam != SIZE_MINIMIZED && g.swapChain) {
			CleanupMainRenderTarget();
			g.swapChain->ResizeBuffers(0, LOWORD(lParam), HIWORD(lParam), DXGI_FORMAT_UNKNOWN, 0);
			CreateMainRenderTarget();
		}
		return 0;
	case WM_CLOSE:
		g.wantClose = true;
		g.PushEvent(D2UI_EVT_CLOSE);
		return 0;
	case WM_DESTROY:
		return 0;
	case WM_SYSCOMMAND:
		if ((wParam & 0xfff0) == SC_KEYMENU)
			return 0;
		break;
	default:
		break;
	}
	return DefWindowProcW(hWnd, msg, wParam, lParam);
}

LRESULT CALLBACK OverlayWndProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam) {
	if (msg == WM_NCHITTEST)
		return HTTRANSPARENT;
	if (msg == WM_CLOSE)
		return 0;
	return DefWindowProcW(hWnd, msg, wParam, lParam);
}

LRESULT CALLBACK DiffWndProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam) {
	ImGuiContext* prev = ImGui::GetCurrentContext();
	if (g.diffCtx) {
		ImGui::SetCurrentContext(g.diffCtx);
		if (ImGui_ImplWin32_WndProcHandler(hWnd, msg, wParam, lParam)) {
			if (prev)
				ImGui::SetCurrentContext(prev);
			return true;
		}
	}
	LRESULT result = 0;
	bool handled = true;
	switch (msg) {
	case WM_SIZE:
		if (g.device && g.diffSwap && wParam != SIZE_MINIMIZED) {
			UINT w = LOWORD(lParam);
			UINT h = HIWORD(lParam);
			if (w > 0 && h > 0) {
				g.context->OMSetRenderTargets(0, nullptr, nullptr);
				CleanupDiffRenderTarget();
				g.diffSwap->ResizeBuffers(0, w, h, DXGI_FORMAT_UNKNOWN, 0);
				CreateDiffRenderTarget();
			}
		}
		break;
	case WM_CLOSE:
		g.showDiff = false;
		break;
	case WM_DESTROY:
		break;
	case WM_SYSCOMMAND:
		if ((wParam & 0xfff0) == SC_KEYMENU)
			break;
		handled = false;
		break;
	default:
		handled = false;
		break;
	}
	if (!handled)
		result = DefWindowProcW(hWnd, msg, wParam, lParam);
	if (prev)
		ImGui::SetCurrentContext(prev);
	return result;
}

bool BottomBarVisible() {
	return g.activeTab <= D2UI_TAB_PAGE2 || g.activeTab == D2UI_TAB_COMPARE || g.activeTab == D2UI_TAB_SPEEDCALC ||
		   g.activeTab == D2UI_TAB_ABOUT || g.activeTab == D2UI_TAB_NOTIFIER;
}

void DrawBottomBar() {
	bool showRead = g.activeTab <= D2UI_TAB_PAGE2 || g.activeTab == D2UI_TAB_COMPARE || g.activeTab == D2UI_TAB_SPEEDCALC;
	bool showCompare = g.activeTab <= D2UI_TAB_PAGE2 || g.activeTab == D2UI_TAB_COMPARE;
	bool showForum = g.activeTab == D2UI_TAB_ABOUT;
	bool showNotify = g.activeTab == D2UI_TAB_NOTIFIER;

	if (showRead) {
		if (ImGui::Button("Read", ImVec2(70, 0)))
			g.PushEvent(D2UI_EVT_READ);
		ImGui::SameLine();
		if (ImGui::Checkbox("Mercenary", &g.mercenary))
			g.PushEvent(D2UI_EVT_MERCENARY, g.mercenary ? 1 : 0);
	}
	if (showCompare) {
		ImGui::SameLine();
		if (ImGui::Button("Compare", ImVec2(80, 0)))
			g.PushEvent(D2UI_EVT_COMPARE);
		ImGui::SameLine();
		if (ImGui::Button("Compare and replace", ImVec2(150, 0)))
			g.PushEvent(D2UI_EVT_COMPARE_REPLACE);
	}
	if (showNotify) {
		if (ImGui::Button("Save", ImVec2(60, 0)))
			g.PushEvent(D2UI_EVT_NOTIFY_SAVE);
		ImGui::SameLine();
		if (ImGui::Button("Reset", ImVec2(60, 0)))
			g.PushEvent(D2UI_EVT_NOTIFY_RESET);
		ImGui::SameLine();
		if (ImGui::Button("Help", ImVec2(60, 0)))
			g.PushEvent(D2UI_EVT_NOTIFY_HELP);
		ImGui::SameLine();
		if (ImGui::Button("Default", ImVec2(70, 0)))
			g.PushEvent(D2UI_EVT_NOTIFY_DEFAULT);
	}
	if (showForum) {
		if (ImGui::Button("Forum", ImVec2(70, 0)))
			g.PushEvent(D2UI_EVT_FORUM);
	}
}

void DrawStatsTab(int tab) {
	int maxLine = 0;
	for (const auto& s : g.stats) {
		if (s.tab == tab)
			maxLine = std::max(maxLine, s.line);
	}
	if (ImGui::BeginTable("stats", 4, ImGuiTableFlags_SizingStretchSame | ImGuiTableFlags_NoPadOuterX)) {
		for (int line = 0; line <= maxLine; ++line) {
			ImGui::TableNextRow();
			for (int col = 0; col < 4; ++col) {
				ImGui::TableSetColumnIndex(col);
				for (const auto& s : g.stats) {
					if (s.tab != tab || s.group != col || s.line != line)
						continue;
					ImGui::TextColored(RgbToVec(s.color), "%s", s.text.c_str());
					if (!s.tooltip.empty() && ImGui::IsItemHovered(ImGuiHoveredFlags_DelayNormal))
						ImGui::SetTooltip("%s", s.tooltip.c_str());
				}
			}
		}
		ImGui::EndTable();
	}
}

void DrawOptionRow(OptionItem& o, size_t index) {
	ImGui::PushID(o.key.c_str());
	if (o.type == "cb") {
		bool v = o.intValue != 0;
		if (ImGui::Checkbox(o.label.c_str(), &v)) {
			o.intValue = v ? 1 : 0;
			g.PushEvent(D2UI_EVT_OPTION, o.intValue, 0, 0, o.key.c_str(), nullptr);
		}
	} else if (o.type == "int") {
		int v = o.intValue;
		ImGui::SetNextItemWidth(140);
		if (ImGui::InputInt("##int", &v, 1, 10)) {
			o.intValue = v;
			g.PushEvent(D2UI_EVT_OPTION, o.intValue, 0, 0, o.key.c_str(), nullptr);
		}
		ImGui::SameLine();
		ImGui::TextUnformatted(o.label.c_str());
	} else if (o.type == "str") {
		int idx = IndexOf(o.choices, o.strValue);
		ImGui::SetNextItemWidth(220);
		if (!o.choices.empty() && ImGui::BeginCombo("##str", o.strValue.c_str())) {
			for (int c = 0; c < static_cast<int>(o.choices.size()); ++c) {
				bool sel = (c == idx);
				if (ImGui::Selectable(o.choices[static_cast<size_t>(c)].c_str(), sel)) {
					o.strValue = o.choices[static_cast<size_t>(c)];
					g.PushEvent(D2UI_EVT_OPTION, 0, 0, 0, o.key.c_str(), o.strValue.c_str());
				}
				if (sel)
					ImGui::SetItemDefaultFocus();
			}
			ImGui::EndCombo();
		}
		ImGui::SameLine();
		ImGui::TextUnformatted(o.label.c_str());
	} else if (o.type == "hk") {
		std::string label = (g.capturingHotkey == static_cast<int>(index)) ? "Press a key (ESC disables)" : HotkeyLabel(o.intValue);
		if (ImGui::Button(label.c_str(), ImVec2(220, 0)))
			g.capturingHotkey = static_cast<int>(index);
		ImGui::SameLine();
		ImGui::TextUnformatted(o.label.c_str());
	}
	ImGui::PopID();
}

void DrawNotifierColors() {
	const float previewH = ImGui::GetTextLineHeightWithSpacing() * 3.6f;
	ImGui::PushStyleColor(ImGuiCol_ChildBg, ImVec4(0.0f, 0.0f, 0.0f, 0.85f));
	ImGui::BeginChild("color_preview", ImVec2(0, previewH), ImGuiChildFlags_Borders);
	ImGui::TextColored(RgbToVec(static_cast<int>(g.notifierColors[4])), "Unique Ring");
	ImGui::TextColored(RgbToVec(static_cast<int>(g.notifierColors[9])), "Rare Circlet");
	ImGui::TextColored(RgbToVec(static_cast<int>(g.notifierColors[3])), "Magic Jewel");
	ImGui::EndChild();
	ImGui::PopStyleColor();

	for (int i = 0; i < 12; ++i) {
		ImGui::PushID(i);
		float col[3];
		UnpackRgb(g.notifierColors[i], col);
		ImGui::SetNextItemWidth(180);
		if (ImGui::ColorEdit3("##c", col, ImGuiColorEditFlags_NoAlpha | ImGuiColorEditFlags_DisplayHex)) {
			g.notifierColors[i] = PackRgb(col);
			g.PushEvent(D2UI_EVT_NOTIFIER_COLOR, i, static_cast<int>(g.notifierColors[i]));
		}
		ImGui::SameLine();
		ImGui::TextColored(RgbToVec(static_cast<int>(g.notifierColors[i])), "%s", kNotifierColorNames[i]);
		ImGui::PopID();
	}
	if (ImGui::Button("Reset colors to defaults")) {
		for (int i = 0; i < 12; ++i) {
			if (g.notifierColors[i] == kDefaultNotifierColors[i])
				continue;
			g.notifierColors[i] = kDefaultNotifierColors[i];
			g.PushEvent(D2UI_EVT_NOTIFIER_COLOR, i, static_cast<int>(g.notifierColors[i]));
		}
	}
}

void DrawSounds();

void FinishOptionsSection(const std::string& section, bool open) {
	if (!open || section.empty())
		return;
	if (section == "Overlay") {
		// Sub-group of Overlay: hidden while the Overlay section is collapsed.
		ImGui::Indent(14.0f);
		if (OptionsSectionHeader("Notification colors"))
			DrawNotifierColors();
		ImGui::Unindent(14.0f);
	} else if (section == "Sounds") {
		DrawSounds();
	}
}

void DrawOptions() {
	std::string current;
	bool open = true;
	for (size_t i = 0; i < g.options.size(); ++i) {
		auto& o = g.options[i];
		if (o.group != 0)
			continue;
		if (o.section != current) {
			FinishOptionsSection(current, open);
			current = o.section.empty() ? "Other" : o.section;
			open = OptionsSectionHeader(current.c_str());
			if (open && current == "General")
				DrawThemeSwitcher();
		}
		if (!open)
			continue;

	}
	FinishOptionsSection(current, open);

	if (OptionsSectionHeader("Hotkeys")) {
		for (size_t i = 0; i < g.options.size(); ++i) {
			auto& o = g.options[i];
			if (o.group != 1)
				continue;
			DrawOptionRow(o, i);
		}
	}
}

void DrawNotifier() {
	ImGui::SetNextItemWidth(180.0f);
	if (ImGui::BeginCombo("##rules", g.notifySelected.c_str())) {
		for (const auto& name : g.notifyRules) {
			bool sel = name == g.notifySelected;
			if (ImGui::Selectable(name.c_str(), sel)) {
				g.notifySelected = name;
				g.PushEvent(D2UI_EVT_NOTIFY_RULES, 0, 0, 0, nullptr, name.c_str());
			}
		}
		ImGui::EndCombo();
	}
	ImGui::SameLine();
	if (ImGui::Button("New"))
		g.PushEvent(D2UI_EVT_NOTIFY_NEW);
	ImGui::SameLine();
	if (ImGui::Button("Rename"))
		g.PushEvent(D2UI_EVT_NOTIFY_RENAME);
	ImGui::SameLine();
	if (ImGui::Button("Delete"))
		g.PushEvent(D2UI_EVT_NOTIFY_DELETE);

	bool save = false;
	ImVec2 size = ImVec2(-1, -1);
	g.notifyEditor.Draw("##notify", g.editorFont, size, &save);
	if (save)
		g.PushEvent(D2UI_EVT_NOTIFY_SAVE);
}

void DrawSounds() {
	for (int i = 0; i < 6; ++i) {
		ImGui::PushID(i);
		ImGui::Text("Sound %d", i + 1);
		ImGui::SameLine(80);
		ImGui::SetNextItemWidth(ImGui::GetContentRegionAvail().x - 80);
		int v = g.volumes[i];
		if (ImGui::SliderInt("##vol", &v, 0, 10)) {
			g.volumes[i] = v;
			g.PushEvent(D2UI_EVT_VOLUME, i, v);
		}
		ImGui::SameLine();
		if (ImGui::Button("Test"))
			g.PushEvent(D2UI_EVT_VOLUME_TEST, i + 1);
		ImGui::PopID();
	}
}

void DrawCompare() {
	char filter[256];
	snprintf(filter, sizeof(filter), "%s", g.compareFilter.c_str());
	ImGui::SetNextItemWidth(ImGui::GetContentRegionAvail().x - 120);
	if (ImGui::InputText("##filter", filter, sizeof(filter))) {
		g.compareFilter = filter;
		g.PushEvent(D2UI_EVT_COMPARE_FILTER, 0, 0, 0, nullptr, filter);
	}
	ImGui::SameLine();
	if (ImGui::Button("All"))
		g.PushEvent(D2UI_EVT_COMPARE_ALL);
	ImGui::SameLine();
	if (ImGui::Button("None"))
		g.PushEvent(D2UI_EVT_COMPARE_NONE);

	ImGui::BeginChild("compare_scroll", ImVec2(0, -8), ImGuiChildFlags_None, ImGuiWindowFlags_AlwaysVerticalScrollbar);
	if (ImGui::BeginTable("compare", 2, ImGuiTableFlags_RowBg | ImGuiTableFlags_BordersInnerV | ImGuiTableFlags_Resizable)) {
		ImGui::TableSetupColumn("ID", ImGuiTableColumnFlags_WidthFixed, 50);
		ImGui::TableSetupColumn("Name");
		ImGui::TableHeadersRow();
		for (auto& it : g.compareItems) {
			ImGui::TableNextRow();
			ImGui::TableSetColumnIndex(0);
			ImGui::PushID(it.statId);
			bool en = it.enabled;
			if (ImGui::Checkbox("##en", &en)) {
				it.enabled = en;
				g.PushEvent(D2UI_EVT_COMPARE_TOGGLE, it.statId, en ? 1 : 0);
			}
			ImGui::SameLine();
			ImGui::Text("%d", it.statId);
			ImGui::TableSetColumnIndex(1);
			ImGui::TextUnformatted(it.name.c_str());
			ImGui::PopID();
		}
		ImGui::EndTable();
	}
	ImGui::EndChild();
}

void DrawDiffWindow() {
	ImGuiViewport* vp = ImGui::GetMainViewport();
	ImGui::SetNextWindowPos(vp->WorkPos);
	ImGui::SetNextWindowSize(vp->WorkSize);
	ImGuiWindowFlags flags = ImGuiWindowFlags_NoDecoration | ImGuiWindowFlags_NoMove | ImGuiWindowFlags_NoSavedSettings |
							 ImGuiWindowFlags_NoBringToFrontOnFocus;
	ImGui::PushStyleVar(ImGuiStyleVar_WindowBorderSize, 0.0f);
	ImGui::PushStyleVar(ImGuiStyleVar_WindowRounding, 0.0f);
	ImGui::Begin("##statdiff", nullptr, flags);
	ImGui::BeginChild("diff_scroll", ImVec2(0, -ImGui::GetFrameHeightWithSpacing() - 4), ImGuiChildFlags_None,
		ImGuiWindowFlags_AlwaysVerticalScrollbar);
	if (ImGui::BeginTable("diff", 5, ImGuiTableFlags_RowBg | ImGuiTableFlags_Borders | ImGuiTableFlags_Resizable)) {
		ImGui::TableSetupColumn("ID", ImGuiTableColumnFlags_WidthFixed, 50);
		ImGui::TableSetupColumn("Name");
		ImGui::TableSetupColumn("Old", ImGuiTableColumnFlags_WidthFixed, 80);
		ImGui::TableSetupColumn("New", ImGuiTableColumnFlags_WidthFixed, 80);
		ImGui::TableSetupColumn("Diff", ImGuiTableColumnFlags_WidthFixed, 80);
		ImGui::TableHeadersRow();
		for (const auto& r : g.diffRows) {
			ImGui::TableNextRow();
			ImGui::TableSetColumnIndex(0);
			ImGui::Text("%d", r.statId);
			ImGui::TableSetColumnIndex(1);
			ImGui::TextUnformatted(r.name.c_str());
			ImGui::TableSetColumnIndex(2);
			ImGui::TextUnformatted(r.oldV.c_str());
			ImGui::TableSetColumnIndex(3);
			ImGui::TextUnformatted(r.newV.c_str());
			ImGui::TableSetColumnIndex(4);
			ImGui::TextUnformatted(r.diff.c_str());
		}
		ImGui::EndTable();
	}
	ImGui::EndChild();
	if (ImGui::Button("Close", ImVec2(100, 0)))
		g.showDiff = false;
	ImGui::End();
	ImGui::PopStyleVar(2);
}

bool EnsureDiffWindow(bool focus) {
	if (!g.device || !g.running)
		return false;
	if (!g.diffWc.lpszClassName) {
		g.diffWc = {};
		g.diffWc.cbSize = sizeof(g.diffWc);
		g.diffWc.style = CS_CLASSDC;
		g.diffWc.lpfnWndProc = DiffWndProc;
		g.diffWc.hInstance = g.instance;
		g.diffWc.hCursor = LoadCursor(nullptr, IDC_ARROW);
		g.diffWc.lpszClassName = L"D2StatsDiff";
		g.diffWc.hIcon = g.icon;
		g.diffWc.hIconSm = g.icon;
		RegisterClassExW(&g.diffWc);
	}
	const bool wasVisible = g.diffHwnd && IsWindowVisible(g.diffHwnd);
	if (!g.diffHwnd) {
		const int clientW = 860;
		const int clientH = 420;
		DWORD style = WS_OVERLAPPEDWINDOW;
		RECT rc{0, 0, clientW, clientH};
		AdjustWindowRect(&rc, style, FALSE);
		int x = CW_USEDEFAULT;
		int y = CW_USEDEFAULT;
		if (g.mainHwnd) {
			RECT mr{};
			GetWindowRect(g.mainHwnd, &mr);
			x = mr.left + 48;
			y = mr.top + 48;
		}
		g.diffHwnd = CreateWindowExW(WS_EX_APPWINDOW, L"D2StatsDiff", L"Stat Differences", style, x, y,
			rc.right - rc.left, rc.bottom - rc.top, nullptr, nullptr, g.instance, nullptr);
		if (!g.diffHwnd)
			return false;
		ApplyWindowFrameColors(g.diffHwnd);
	}
	if (!g.diffSwap && !CreateDiffSwapChain())
		return false;
	if (!g.diffCtx) {
		g.diffCtx = ImGui::CreateContext();
		ImGui::SetCurrentContext(g.diffCtx);
		ApplyThemeToCurrentContext();
		ApplyWindowFrameColors(g.diffHwnd);
		ImGuiIO& io = ImGui::GetIO();
		io.IniFilename = nullptr;
		io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;
		LoadUiFont(g.diffCtx);
		ImGui_ImplWin32_Init(g.diffHwnd);
		ImGui_ImplDX11_Init(g.device, g.context);
		if (g.mainCtx)
			ImGui::SetCurrentContext(g.mainCtx);
	}
	if (!IsWindowVisible(g.diffHwnd))
		ShowWindow(g.diffHwnd, SW_SHOW);
		ApplyWindowFrameColors(g.diffHwnd);
	if (focus && !wasVisible)
		SetForegroundWindow(g.diffHwnd);
	return true;
}

void PresentDiff() {
	if (!g.showDiff) {
		if (g.diffHwnd && IsWindowVisible(g.diffHwnd))
			ShowWindow(g.diffHwnd, SW_HIDE);
		if (g.mainCtx)
			ImGui::SetCurrentContext(g.mainCtx);
		return;
	}
	if (!g.diffHwnd || !g.diffCtx || !g.diffRtv || !g.diffSwap) {
		if (!EnsureDiffWindow(false))
			return;
	}
	if (!g.diffCtx || !g.diffRtv || !g.diffSwap)
		return;
	if (IsIconic(g.diffHwnd))
		return;
	RECT crc{};
	GetClientRect(g.diffHwnd, &crc);
	if (crc.right - crc.left < 1 || crc.bottom - crc.top < 1)
		return;

	ImGui::SetCurrentContext(g.diffCtx);
	ImGui_ImplDX11_NewFrame();
	ImGui_ImplWin32_NewFrame();
	ImGui::NewFrame();
	DrawDiffWindow();
	ImGui::Render();

	ImVec4 diffBg = ImGui::GetStyleColorVec4(ImGuiCol_WindowBg);
	const float clear[4] = {diffBg.x, diffBg.y, diffBg.z, 1.0f};
	g.context->OMSetRenderTargets(1, &g.diffRtv, nullptr);
	g.context->ClearRenderTargetView(g.diffRtv, clear);
	ImGui_ImplDX11_RenderDrawData(ImGui::GetDrawData());
	g.diffSwap->Present(0, 0);

	if (!g.showDiff && g.diffHwnd)
		ShowWindow(g.diffHwnd, SW_HIDE);
	if (g.mainCtx)
		ImGui::SetCurrentContext(g.mainCtx);
}

void DestroyDiffUi() {
	if (g.diffCtx) {
		ImGui::SetCurrentContext(g.diffCtx);
		ImGui_ImplDX11_Shutdown();
		ImGui_ImplWin32_Shutdown();
		ImGui::DestroyContext(g.diffCtx);
		g.diffCtx = nullptr;
	}
	CleanupDiffRenderTarget();
	if (g.diffSwap) {
		g.diffSwap->Release();
		g.diffSwap = nullptr;
	}
	if (g.diffHwnd) {
		DestroyWindow(g.diffHwnd);
		g.diffHwnd = nullptr;
	}
	if (g.diffWc.lpszClassName) {
		UnregisterClassW(L"D2StatsDiff", g.instance);
		g.diffWc = {};
	}
	if (g.mainCtx)
		ImGui::SetCurrentContext(g.mainCtx);
}

void DrawSpeedCalcCombo(int which, float width = -FLT_MIN) {
	const char* preview = g.scSelected[which].empty() ? "Auto" : g.scSelected[which].c_str();
	int idx = IndexOf(g.scCombo[which], g.scSelected[which]);
	ImGui::SetNextItemWidth(width);
	if (ImGui::BeginCombo("##combo", preview)) {
		for (int c = 0; c < static_cast<int>(g.scCombo[which].size()); ++c) {
			bool sel = (c == idx);
			if (ImGui::Selectable(g.scCombo[which][static_cast<size_t>(c)].c_str(), sel)) {
				g.scSelected[which] = g.scCombo[which][static_cast<size_t>(c)];
				g.PushEvent(D2UI_EVT_SC_COMBO, which, 0, 0, nullptr, g.scSelected[which].c_str());
			}
			if (sel)
				ImGui::SetItemDefaultFocus();
		}
		ImGui::EndCombo();
	}
}

void DrawSpeedCalc() {
	const char* comboLabels[5] = {"Class", "Morph", "Weapon Type", "Weapon Base", "Debuff"};
	if (ImGui::BeginTable("sccombos", 4, ImGuiTableFlags_SizingStretchSame | ImGuiTableFlags_NoPadOuterX)) {
		ImGui::TableSetupColumn("class");
		ImGui::TableSetupColumn("morph");
		ImGui::TableSetupColumn("wtype");
		ImGui::TableSetupColumn("wbase");
		ImGui::TableNextRow();
		for (int i = 0; i < 4; ++i) {
			ImGui::TableSetColumnIndex(i);
			ImGui::PushID(i);
			ImGui::TextUnformatted(comboLabels[i]);
			ImGui::BeginDisabled(i == 1 && !g.scMorphEnabled);
			DrawSpeedCalcCombo(i);
			ImGui::EndDisabled();
			ImGui::PopID();
		}
		ImGui::EndTable();
	}

	const char* inputs[5] = {"IAS", "Skill IAS", "FCR", "FHR", "FBR"};
	if (ImGui::BeginTable("scinputs", 6, ImGuiTableFlags_SizingStretchSame | ImGuiTableFlags_NoPadOuterX)) {
		ImGui::TableNextRow();
		for (int i = 0; i < 5; ++i) {
			ImGui::TableSetColumnIndex(i);
			ImGui::PushID(100 + i);
			ImGui::TextUnformatted(inputs[i]);
			char buf[32];
			snprintf(buf, sizeof(buf), "%s", g.scInput[i].c_str());
			ImGui::SetNextItemWidth(-FLT_MIN);
			if (ImGui::InputText("##in", buf, sizeof(buf))) {
				g.scInput[i] = buf;
				g.PushEvent(D2UI_EVT_SC_INPUT, i, 0, 0, nullptr, buf);
			}
			ImGui::PopID();
		}
		ImGui::TableSetColumnIndex(5);
		ImGui::PushID(105);
		ImGui::TextUnformatted("Debuff");
		DrawSpeedCalcCombo(4);
		ImGui::PopID();
		ImGui::EndTable();
	}
	if (g.scCheckVisible[0]) {
		if (ImGui::Checkbox("Dual Wield", &g.scCheck[0]))
			g.PushEvent(D2UI_EVT_SC_CHECK, 0, g.scCheck[0] ? 1 : 0);
	}
	if (g.scCheckVisible[1]) {
		if (g.scCheckVisible[0])
			ImGui::SameLine();
		if (ImGui::Checkbox("Throw", &g.scCheck[1]))
			g.PushEvent(D2UI_EVT_SC_CHECK, 1, g.scCheck[1] ? 1 : 0);
	}

	ImGui::TextDisabled("%s", g.scStatus.c_str());

	const char* tables[4] = {"Attack Speed", "Cast Speed", "Hit Recovery", "Block Speed"};
	if (ImGui::BeginTable("sctables", 4, ImGuiTableFlags_SizingStretchSame)) {
		ImGui::TableNextRow();
		for (int t = 0; t < 4; ++t) {
			ImGui::TableSetColumnIndex(t);
			ImGui::PushID(200 + t);
			ImGui::TextUnformatted(tables[t]);
			ImGui::BeginChild("bpwrap", ImVec2(0, 180), ImGuiChildFlags_Borders, ImGuiWindowFlags_AlwaysVerticalScrollbar);
			if (ImGui::BeginTable("bp", 2, ImGuiTableFlags_RowBg | ImGuiTableFlags_BordersInnerV)) {
				ImGui::TableSetupColumn("Frm", ImGuiTableColumnFlags_WidthFixed, 40);
				ImGui::TableSetupColumn("Value");
				ImGui::TableHeadersRow();
				for (int r = 0; r < static_cast<int>(g.scTables[t].rows.size()); ++r) {
					ImGui::TableNextRow();
					if (r == g.scTables[t].highlight)
						ImGui::TableSetBgColor(ImGuiTableBgTarget_RowBg0, IM_COL32(255, 191, 0, 90));
					ImGui::TableSetColumnIndex(0);
					ImGui::TextUnformatted(g.scTables[t].rows[static_cast<size_t>(r)].first.c_str());
					ImGui::TableSetColumnIndex(1);
					ImGui::TextUnformatted(g.scTables[t].rows[static_cast<size_t>(r)].second.c_str());
				}
				ImGui::EndTable();
			}
			ImGui::EndChild();
			ImGui::PopID();
		}
		ImGui::EndTable();
	}
}

void DrawAbout() {
	ImGui::TextUnformatted("Made by Wojen and Kyromyr, using Shaggi's offsets.");
	ImGui::TextUnformatted("Layout help by krys.");
	ImGui::TextUnformatted("Additional help by suchbalance and Quirinus.");
	ImGui::TextUnformatted("Sounds by MurderManTX and Cromi38.");
	ImGui::TextUnformatted("ImGui themes by TheAncientOwl (modified by Azadi)");
	ImGui::Dummy(ImVec2(0, 8));
	ImGui::TextWrapped("If you're unsure what any of the abbreviations mean, all of them should have a tooltip when hovered over.");
	ImGui::Dummy(ImVec2(0, 8));
	ImGui::TextUnformatted("Hotkeys can be disabled by setting them to ESC.");
}

void DrawTabContents(int tab) {
	if (tab <= D2UI_TAB_PAGE2)
		DrawStatsTab(tab);
	else if (tab == D2UI_TAB_NOTIFIER)
		DrawNotifier();
	else if (tab == D2UI_TAB_SPEEDCALC)
		DrawSpeedCalc();
	else if (tab == D2UI_TAB_COMPARE)
		DrawCompare();
	else if (tab == D2UI_TAB_OPTIONS)
		DrawOptions();
	else
		DrawAbout();
}

void DrawTabStrip() {
	const char* names[] = {"Basic", "Page 1", "Page 2", "Notifier", "Speedcalc", "Compare", "Options", "About"};
	const int nTabs = IM_ARRAYSIZE(names);
	const int cols = 4;
	const int rows = 2;
	const float height = ImGui::GetFrameHeight();
	const float overline = std::max(ImGui::GetStyle().TabBarOverlineSize, 2.0f);
	const float rounding = ImGui::GetStyle().TabRounding;
	ImDrawList* dl = ImGui::GetWindowDrawList();
	ImGui::PushStyleVar(ImGuiStyleVar_ItemSpacing, ImVec2(0.0f, 0.0f));
	for (int row = 0; row < rows; ++row) {
		const int rowStart = row * cols;
		int rowCount = nTabs - rowStart;
		if (rowCount <= 0)
			break;
		if (rowCount > cols)
			rowCount = cols;
		const float avail = ImGui::GetContentRegionAvail().x;
		const float tabW = avail / static_cast<float>(rowCount);
		const ImVec2 rowPos = ImGui::GetCursorScreenPos();
		for (int col = 0; col < rowCount; ++col) {
			const int t = rowStart + col;
			const float x0 = rowPos.x + tabW * static_cast<float>(col);
			const float x1 = (col == rowCount - 1) ? (rowPos.x + avail) : (rowPos.x + tabW * static_cast<float>(col + 1));
			ImGui::SetCursorScreenPos(ImVec2(x0, rowPos.y));
			ImGui::PushID(t);
			if (ImGui::InvisibleButton("tab", ImVec2(x1 - x0, height))) {
				if (g.activeTab != t) {
					g.activeTab = t;
					g.PushEvent(D2UI_EVT_TAB, t);
				}
			}
			const bool selected = g.activeTab == t;
			const bool hovered = ImGui::IsItemHovered();
			ImU32 bg = ImGui::GetColorU32(selected ? ImGuiCol_TabSelected : hovered ? ImGuiCol_TabHovered : ImGuiCol_Tab);
			dl->AddRectFilled(ImVec2(x0, rowPos.y), ImVec2(x1, rowPos.y + height), bg, rounding, ImDrawFlags_RoundCornersTop);
			if (selected)
				// Highlight bar along the bottom edge of the selected tab.
				dl->AddRectFilled(ImVec2(x0, rowPos.y + height - overline), ImVec2(x1, rowPos.y + height), ImGui::GetColorU32(ImGuiCol_TabSelectedOverline));
			const ImVec2 textSz = ImGui::CalcTextSize(names[t]);
			dl->AddText(ImVec2(x0 + (x1 - x0 - textSz.x) * 0.5f, rowPos.y + (height - textSz.y) * 0.5f),
				ImGui::GetColorU32(ImGuiCol_Text), names[t]);
			ImGui::PopID();
		}
		ImGui::SetCursorScreenPos(rowPos);
		ImGui::Dummy(ImVec2(avail, height));
	}
	ImVec2 line = ImGui::GetCursorScreenPos();
	dl->AddLine(line, ImVec2(line.x + ImGui::GetContentRegionAvail().x, line.y), ImGui::GetColorU32(ImGuiCol_Border));
	ImGui::PopStyleVar();
	ImGui::Dummy(ImVec2(0, 6.0f));
}

void DrawMainUi() {
	ImGuiViewport* vp = ImGui::GetMainViewport();
	ImGui::SetNextWindowPos(vp->WorkPos);
	ImGui::SetNextWindowSize(vp->WorkSize);
	ImGui::PushStyleVar(ImGuiStyleVar_WindowPadding, ImVec2(8.0f, 4.0f));
	// The native frame already draws the window border, so the ImGui one would show
	// up as a second, inset border.
	ImGui::PushStyleVar(ImGuiStyleVar_WindowBorderSize, 0.0f);
	ImGui::PushStyleVar(ImGuiStyleVar_WindowRounding, 0.0f);
	ImGuiWindowFlags flags = ImGuiWindowFlags_NoDecoration | ImGuiWindowFlags_NoMove | ImGuiWindowFlags_NoSavedSettings |
							 ImGuiWindowFlags_NoScrollbar | ImGuiWindowFlags_NoScrollWithMouse;
	ImGui::Begin("D2Stats", nullptr, flags);

	const bool showBottom = BottomBarVisible();
	const float bottomH = showBottom ? (ImGui::GetFrameHeight() + 4.0f) : 0.0f;
	DrawTabStrip();

	const bool innerScrolls =
		g.activeTab == D2UI_TAB_NOTIFIER || g.activeTab == D2UI_TAB_COMPARE;
	ImGuiWindowFlags bodyFlags = innerScrolls
		? (ImGuiWindowFlags_NoScrollbar | ImGuiWindowFlags_NoScrollWithMouse)
		: ImGuiWindowFlags_AlwaysVerticalScrollbar;
	ImGui::BeginChild("tabbody", ImVec2(0, showBottom ? -bottomH : 0.0f), ImGuiChildFlags_None, bodyFlags);
	DrawTabContents(g.activeTab);
	ImGui::EndChild();

	if (showBottom)
		DrawBottomBar();
	ImGui::End();
	ImGui::PopStyleVar(3);

	if (g.capturingHotkey >= 0) {
		int code = CaptureHotkey();
		if (code >= 0 && g.capturingHotkey < static_cast<int>(g.options.size())) {
			auto& o = g.options[static_cast<size_t>(g.capturingHotkey)];
			o.intValue = code;
			g.PushEvent(D2UI_EVT_HOTKEY, code, 0, 0, o.key.c_str(), nullptr);
			g.capturingHotkey = -1;
		}
	}
}

void DrawOverlayUi(int w, int h) {
	ImGui::SetNextWindowPos(ImVec2(0, 0));
	ImGui::SetNextWindowSize(ImVec2(static_cast<float>(w), static_cast<float>(h)));
	ImGuiWindowFlags flags = ImGuiWindowFlags_NoDecoration | ImGuiWindowFlags_NoInputs | ImGuiWindowFlags_NoNav |
							 ImGuiWindowFlags_NoSavedSettings | ImGuiWindowFlags_NoBackground | ImGuiWindowFlags_NoMove;
	ImGui::Begin("##overlay", nullptr, flags);
	ImGui::PushStyleVar(ImGuiStyleVar_ItemSpacing, ImVec2(0.0f, static_cast<float>(g.overlayLineSpacing)));
	if (g.overlayFont)
		ImGui::PushFont(g.overlayFont);
	for (const auto& line : g.overlayLines) {
		ImVec2 p = ImGui::GetCursorScreenPos();
		ImVec2 sz = ImGui::CalcTextSize(line.text.c_str());
		if (g.overlayContrast) {
			ImGui::GetWindowDrawList()->AddRectFilled(p, ImVec2(p.x + sz.x + 6.0f, p.y + sz.y), IM_COL32(10, 10, 10, 230));
		}
		ImGui::TextColored(RgbToVec(static_cast<int>(line.color)), "%s", line.text.c_str());
		if (line.gapAfter)
			ImGui::Dummy(ImVec2(0, 2));
	}
	if (g.overlayFont)
		ImGui::PopFont();
	ImGui::PopStyleVar();
	ImGui::End();
}

void ExpireOverlay() {
	ULONGLONG now = GetTickCount64();
	g.overlayLines.erase(std::remove_if(g.overlayLines.begin(), g.overlayLines.end(),
							 [now](const OverlayLine& l) { return l.expireAt != 0 && now >= l.expireAt; }),
		g.overlayLines.end());
}

void PresentOverlay() {
	if (!g.overlayHwnd)
		return;
	bool show = g.overlayWantVisible && g.overlayW > 0 && g.overlayH > 0;
	ShowWindow(g.overlayHwnd, show ? SW_SHOWNOACTIVATE : SW_HIDE);
	if (!show)
		return;
	if (!EnsureOverlayBuffers(g.overlayW, g.overlayH))
		return;

	ImGui::SetCurrentContext(g.overlayCtx);
	ImGuiIO& io = ImGui::GetIO();
	io.DisplaySize = ImVec2(static_cast<float>(g.overlayW), static_cast<float>(g.overlayH));
	io.DeltaTime = 1.0f / 60.0f;
	ImGui_ImplDX11_NewFrame();
	ImGui::NewFrame();
	DrawOverlayUi(g.overlayW, g.overlayH);
	ImGui::Render();

	const float clear[4] = {0, 0, 0, 0};
	g.context->OMSetRenderTargets(1, &g.overlayRtv, nullptr);
	g.context->ClearRenderTargetView(g.overlayRtv, clear);
	D3D11_VIEWPORT vp{};
	vp.Width = static_cast<float>(g.overlayW);
	vp.Height = static_cast<float>(g.overlayH);
	vp.MaxDepth = 1.0f;
	g.context->RSSetViewports(1, &vp);
	ImGui_ImplDX11_RenderDrawData(ImGui::GetDrawData());
	g.context->CopyResource(g.overlayStaging, g.overlayTex);

	D3D11_MAPPED_SUBRESOURCE mapped{};
	if (SUCCEEDED(g.context->Map(g.overlayStaging, 0, D3D11_MAP_READ, 0, &mapped)) && g.overlayBits) {
		auto* dst = static_cast<unsigned char*>(g.overlayBits);
		auto* src = static_cast<unsigned char*>(mapped.pData);
		for (int y = 0; y < g.overlayH; ++y) {
			auto* srow = src + y * mapped.RowPitch;
			auto* drow = dst + y * g.overlayW * 4;
			for (int x = 0; x < g.overlayW; ++x) {
				unsigned char r = srow[x * 4 + 0];
				unsigned char gr = srow[x * 4 + 1];
				unsigned char b = srow[x * 4 + 2];
				unsigned char a = srow[x * 4 + 3];
				drow[x * 4 + 0] = static_cast<unsigned char>(b * a / 255);
				drow[x * 4 + 1] = static_cast<unsigned char>(gr * a / 255);
				drow[x * 4 + 2] = static_cast<unsigned char>(r * a / 255);
				drow[x * 4 + 3] = a;
			}
		}
		g.context->Unmap(g.overlayStaging, 0);
	}

	POINT ptSrc{0, 0};
	POINT ptDst{g.overlayX, g.overlayY};
	SIZE size{g.overlayW, g.overlayH};
	BLENDFUNCTION blend{AC_SRC_OVER, 0, 255, AC_SRC_ALPHA};
	UpdateLayeredWindow(g.overlayHwnd, nullptr, &ptDst, &size, g.overlayHdc, &ptSrc, 0, &blend, ULW_ALPHA);
	SetWindowPos(g.overlayHwnd, HWND_TOPMOST, g.overlayX, g.overlayY, g.overlayW, g.overlayH, SWP_NOACTIVATE);
}

} // namespace

extern "C" {

int D2UI_CALL D2Ui_Init(const wchar_t* title, int width, int height, const wchar_t* iconPath) {
	if (g.running)
		return 1;
	g.instance = GetModuleHandleW(nullptr);
	g.scStatus = "Empty fields use live item/skill stats. Auto follows class, morph, and weapon.";

	g.mainWc = {};
	g.mainWc.cbSize = sizeof(g.mainWc);
	g.mainWc.style = CS_CLASSDC;
	g.mainWc.lpfnWndProc = MainWndProc;
	g.mainWc.hInstance = g.instance;
	g.mainWc.hCursor = LoadCursor(nullptr, IDC_ARROW);
	g.mainWc.lpszClassName = L"D2StatsMain";
	if (iconPath && *iconPath)
		g.icon = ExtractIconW(g.instance, iconPath, 0);
	g.mainWc.hIcon = g.icon;
	g.mainWc.hIconSm = g.icon;
	RegisterClassExW(&g.mainWc);

	g.overlayWc = g.mainWc;
	g.overlayWc.lpfnWndProc = OverlayWndProc;
	g.overlayWc.lpszClassName = L"D2StatsOverlay";
	g.overlayWc.hIcon = nullptr;
	g.overlayWc.hIconSm = nullptr;
	RegisterClassExW(&g.overlayWc);

	int w = width > 0 ? width : 572;
	int h = height > 0 ? height : 370;
	DWORD style = WS_OVERLAPPEDWINDOW;
	RECT rc{0, 0, w, h};
	AdjustWindowRect(&rc, style, FALSE);
	g.mainHwnd = CreateWindowW(L"D2StatsMain", title ? title : L"D2Stats", style, CW_USEDEFAULT, CW_USEDEFAULT,
		rc.right - rc.left, rc.bottom - rc.top, nullptr, nullptr, g.instance, nullptr);
	if (!g.mainHwnd)
		return 0;

	g.overlayHwnd = CreateWindowExW(WS_EX_LAYERED | WS_EX_TOPMOST | WS_EX_TOOLWINDOW | WS_EX_TRANSPARENT | WS_EX_NOACTIVATE,
		L"D2StatsOverlay", L"D2StatsOverlay", WS_POPUP, 0, 0, 64, 64, nullptr, nullptr, g.instance, nullptr);
	if (!g.overlayHwnd)
		return 0;

	if (!CreateDevice(g.mainHwnd))
		return 0;

	IMGUI_CHECKVERSION();
	g.mainCtx = ImGui::CreateContext();
	ImGui::SetCurrentContext(g.mainCtx);
	LoadThemesFromIni();
	LoadTheme();
	LoadSectionOpen();
	ApplyThemeToCurrentContext();
	ImGuiIO& io = ImGui::GetIO();
	io.IniFilename = nullptr;
	io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;
	LoadUiFont(g.mainCtx);
	ImGui_ImplWin32_Init(g.mainHwnd);
	ImGui_ImplDX11_Init(g.device, g.context);

	g.overlayCtx = ImGui::CreateContext();
	ImGui::SetCurrentContext(g.overlayCtx);
	ApplyThemeToCurrentContext();
	ImGuiIO& oio = ImGui::GetIO();
	oio.IniFilename = nullptr;
	oio.ConfigFlags |= ImGuiConfigFlags_NoMouse;
	ImGui_ImplDX11_Init(g.device, g.context);
	RebuildOverlayFont();

	ImGui::SetCurrentContext(g.mainCtx);
	ShowWindow(g.mainHwnd, SW_SHOW);
	ApplyWindowFrameColors(g.mainHwnd);
	UpdateWindow(g.mainHwnd);
	g.running = true;
	g.wantClose = false;
	return 1;
}

void D2UI_CALL D2Ui_Shutdown() {
	DestroyDiffUi();
	if (g.overlayCtx) {
		ImGui::SetCurrentContext(g.overlayCtx);
		ImGui_ImplDX11_Shutdown();
		ImGui::DestroyContext(g.overlayCtx);
		g.overlayCtx = nullptr;
	}
	if (g.mainCtx) {
		ImGui::SetCurrentContext(g.mainCtx);
		ImGui_ImplDX11_Shutdown();
		ImGui_ImplWin32_Shutdown();
		ImGui::DestroyContext(g.mainCtx);
		g.mainCtx = nullptr;
	}
	DestroyDevice();
	if (g.overlayHwnd) {
		DestroyWindow(g.overlayHwnd);
		g.overlayHwnd = nullptr;
	}
	if (g.mainHwnd) {
		DestroyWindow(g.mainHwnd);
		g.mainHwnd = nullptr;
	}
	if (g.icon) {
		DestroyIcon(g.icon);
		g.icon = nullptr;
	}
	UnregisterClassW(L"D2StatsMain", g.instance);
	UnregisterClassW(L"D2StatsOverlay", g.instance);
	g.running = false;
	g.events.clear();
}

int D2UI_CALL D2Ui_Tick() {
	if (!g.running)
		return 0;

	// DWM ignores the caption/border colours unless they are set while the window
	// is the foreground one, and it drops them when they are set in the same moment
	// the window becomes active - so apply them shortly after each activation, and
	// again when the theme changed.
	{
		static int appliedTheme = -1;
		static ULONGLONG focusedSince = 0;
		static ULONGLONG appliedAt = 0;
		const ULONGLONG now = GetTickCount64();
		if (g.mainHwnd && GetForegroundWindow() == g.mainHwnd) {
			if (!focusedSince)
				focusedSince = now;
			const bool themeChanged = appliedTheme != g.theme;
			if (now - focusedSince >= 500 && (themeChanged || appliedAt < focusedSince)) {
				ApplyWindowFrameColors(g.mainHwnd);
				appliedTheme = g.theme;
				appliedAt = now;
			}
		} else {
			focusedSince = 0;
		}
	}
	MSG msg;
	while (PeekMessageW(&msg, g.mainHwnd, 0, 0, PM_REMOVE)) {
		TranslateMessage(&msg);
		DispatchMessageW(&msg);
	}
	while (PeekMessageW(&msg, g.overlayHwnd, 0, 0, PM_REMOVE)) {
		TranslateMessage(&msg);
		DispatchMessageW(&msg);
	}
	if (g.diffHwnd) {
		while (PeekMessageW(&msg, g.diffHwnd, 0, 0, PM_REMOVE)) {
			TranslateMessage(&msg);
			DispatchMessageW(&msg);
		}
	}

	if (g.wantClose)
		return 0;

	ExpireOverlay();

	// Rebuilding the atlas invalidates the font texture, so it is done between
	// frames instead of in the middle of drawing the options tab.
	if (g.wantMainFontRebuild) {
		g.wantMainFontRebuild = false;
		RebuildMainFonts();
	}

	ImGui::SetCurrentContext(g.mainCtx);
	ImGui_ImplDX11_NewFrame();
	ImGui_ImplWin32_NewFrame();
	ImGui::NewFrame();
	DrawMainUi();
	ImGui::Render();

	ImVec4 bg = ImGui::GetStyleColorVec4(ImGuiCol_WindowBg);
	const float clear[4] = {bg.x, bg.y, bg.z, 1.0f};
	g.context->OMSetRenderTargets(1, &g.mainRtv, nullptr);
	g.context->ClearRenderTargetView(g.mainRtv, clear);
	ImGui_ImplDX11_RenderDrawData(ImGui::GetDrawData());
	g.swapChain->Present(1, 0);

	PresentDiff();
	PresentOverlay();
	return g.wantClose ? 0 : 1;
}

void* D2UI_CALL D2Ui_GetMainHwnd() {
	return g.mainHwnd;
}

int D2UI_CALL D2Ui_PollEvent(D2UiEvent* out) {
	if (!out || g.events.empty())
		return 0;
	*out = g.events.front();
	g.events.pop_front();
	return 1;
}

int D2UI_CALL D2Ui_GetActiveTab() {
	return g.activeTab;
}

void D2UI_CALL D2Ui_OverlaySetTarget(int x, int y, int w, int h, int visible) {
	g.overlayX = x;
	g.overlayY = y;
	g.overlayW = w;
	g.overlayH = h;
	g.overlayWantVisible = visible != 0;
}

void D2UI_CALL D2Ui_Print(const wchar_t* text, unsigned int colorRgb, int timeoutMs) {
	OverlayLine line;
	line.text = WideToUtf8(text);
	line.color = colorRgb ? colorRgb : 0xFFFFFF;
	line.expireAt = timeoutMs <= 0 ? 0 : GetTickCount64() + static_cast<ULONGLONG>(timeoutMs);
	g.overlayLines.push_back(std::move(line));
}

void D2UI_CALL D2Ui_OverlayAddGap() {
	if (!g.overlayLines.empty())
		g.overlayLines.back().gapAfter = true;
}

void D2UI_CALL D2Ui_OverlayClear() {
	g.overlayLines.clear();
}

void D2UI_CALL D2Ui_SetEditorFont(const wchar_t* font) {
	std::string name = font && *font ? WideToUtf8(font) : "Courier New";
	if (name == g.editorFontName)
		return;
	g.editorFontName = name;
	g.wantMainFontRebuild = true;
}
void D2UI_CALL D2Ui_SetEditorFontSize(int size) {
	int v = size < 6 ? 6 : (size > 48 ? 48 : size);
	if (v == g.editorFontSize)
		return;
	g.editorFontSize = v;
	g.wantMainFontRebuild = true;
}
void D2UI_CALL D2Ui_OverlayConfigure(const wchar_t* font, int fontSize, int timeoutMs, int contrast, int lineSpacing) {
	std::string name = font ? WideToUtf8(font) : "Courier New";
	int size = fontSize > 0 ? fontSize : 12;
	bool fontChanged = name != g.overlayFontName || size != g.overlayFontSize;
	g.overlayFontName = name;
	g.overlayFontSize = size;
	g.overlayTimeoutMs = timeoutMs;
	g.overlayContrast = contrast != 0;
	if (lineSpacing < 0)
		lineSpacing = 0;
	if (lineSpacing > 64)
		lineSpacing = 64;
	g.overlayLineSpacing = lineSpacing;
	if (fontChanged && g.overlayCtx)
		RebuildOverlayFont();
	// The rule editor mirrors the overlay font so the notifier text looks the
	// same where it is written and where it is shown.
	if (fontChanged)
		g.wantMainFontRebuild = true;
}

int D2UI_CALL D2Ui_OverlayIsVisible() {
	return g.overlayWantVisible ? 1 : 0;
}

void D2UI_CALL D2Ui_ClearStats() {
	g.stats.clear();
}

int D2UI_CALL D2Ui_AddStat(int tab, int group, int line, const wchar_t* text, const wchar_t* tooltip, int colorRgb, int header) {
	StatItem s;
	s.tab = tab;
	s.group = group;
	s.line = line;
	s.text = WideToUtf8(text);
	s.tooltip = WideToUtf8(tooltip);
	s.color = colorRgb;
	s.header = header != 0;
	g.stats.push_back(std::move(s));
	return static_cast<int>(g.stats.size() - 1);
}

void D2UI_CALL D2Ui_UpdateStat(int index, const wchar_t* text, int colorRgb) {
	if (index < 0 || index >= static_cast<int>(g.stats.size()))
		return;
	if (g.stats[static_cast<size_t>(index)].header)
		return;
	g.stats[static_cast<size_t>(index)].text = WideToUtf8(text);
	if (colorRgb >= 0)
		g.stats[static_cast<size_t>(index)].color = colorRgb;
}

void D2UI_CALL D2Ui_SetMercenary(int checked) {
	g.mercenary = checked != 0;
}

void D2UI_CALL D2Ui_ClearOptions() {
	g.options.clear();
}

void D2UI_CALL D2Ui_AddOption(int group, const wchar_t* key, const wchar_t* type, const wchar_t* label, int intValue, const wchar_t* strValue, const wchar_t* section) {
	OptionItem o;
	o.group = group;
	o.key = WideToUtf8(key);
	o.type = WideToUtf8(type);
	o.label = WideToUtf8(label);
	o.section = WideToUtf8(section);
	o.intValue = intValue;
	o.strValue = WideToUtf8(strValue);
	g.options.push_back(std::move(o));
}

void D2UI_CALL D2Ui_SetNotifierColor(int index, unsigned int colorRgb) {
	if (index >= 0 && index < 12)
		g.notifierColors[index] = colorRgb & 0xFFFFFFu;
}

void D2UI_CALL D2Ui_SetOptionChoices(const wchar_t* key, const wchar_t* pipeList) {
	auto* o = g.FindOption(WideToUtf8(key));
	if (!o)
		return;
	o->choices = SplitPipe(WideToUtf8(pipeList));
}

void D2UI_CALL D2Ui_SetOptionInt(const wchar_t* key, int value) {
	auto* o = g.FindOption(WideToUtf8(key));
	if (o)
		o->intValue = value;
}

void D2UI_CALL D2Ui_SetOptionStr(const wchar_t* key, const wchar_t* value) {
	auto* o = g.FindOption(WideToUtf8(key));
	if (o)
		o->strValue = WideToUtf8(value);
}

void D2UI_CALL D2Ui_SetNotifyRules(const wchar_t* pipeList, const wchar_t* selected) {
	g.notifyRules = SplitPipe(WideToUtf8(pipeList));
	g.notifySelected = WideToUtf8(selected);
}

void D2UI_CALL D2Ui_SetNotifierText(const wchar_t* text) {
	g.notifyEditor.SetText(WideToUtf8(text));
	// Remember the normalized text so D2Ui_IsNotifierDirty() compares like with like.
	g.notifySaved = g.notifyEditor.GetText();
}

void D2UI_CALL D2Ui_SetNotifierEdit(const wchar_t* text) {
	g.notifyEditor.SetText(WideToUtf8(text));
}

void D2UI_CALL D2Ui_SetNotifierKeywords(const wchar_t* pipeList) {
	g.notifyEditor.SetKeywords(WideToUtf8(pipeList));
}

void D2UI_CALL D2Ui_SetNotifierItemNames(const wchar_t* pipeList) {
	g.notifyEditor.SetItemNames(WideToUtf8(pipeList));
}

void D2UI_CALL D2Ui_AddNotifierItemNames(const wchar_t* pipeList) {
	g.notifyEditor.AppendItemNames(WideToUtf8(pipeList));
}

int D2UI_CALL D2Ui_GetNotifierText(wchar_t* buf, int cch) {
	// Hand the text back with CRLF endings so rule files keep the format the rest
	// of the AutoIt side expects.
	const std::string& raw = g.notifyEditor.GetText();
	std::string crlf;
	crlf.reserve(raw.size() + 64);
	for (char c : raw) {
		if (c == '\n')
			crlf.push_back('\r');
		crlf.push_back(c);
	}
	std::wstring w = Utf8ToWide(crlf.c_str());
	if (!buf || cch <= 0)
		return static_cast<int>(w.size());
	CopyWide(buf, cch, w.c_str());
	return static_cast<int>(w.size());
}

int D2UI_CALL D2Ui_IsNotifierDirty() {
	return g.notifyEditor.GetText() != g.notifySaved ? 1 : 0;
}

int D2UI_CALL D2Ui_GetNotifyRulesSelected(wchar_t* buf, int cch) {
	std::wstring w = Utf8ToWide(g.notifySelected.c_str());
	if (!buf || cch <= 0)
		return static_cast<int>(w.size());
	CopyWide(buf, cch, w.c_str());
	return static_cast<int>(w.size());
}

void D2UI_CALL D2Ui_SetVolume(int index, int value) {
	if (index >= 0 && index < 6)
		g.volumes[index] = value;
}

int D2UI_CALL D2Ui_GetVolume(int index) {
	if (index >= 0 && index < 6)
		return g.volumes[index];
	return 0;
}

void D2UI_CALL D2Ui_SetCompareFilter(const wchar_t* filter) {
	g.compareFilter = WideToUtf8(filter);
}

void D2UI_CALL D2Ui_ClearCompareList() {
	g.compareItems.clear();
}

void D2UI_CALL D2Ui_AddCompareItem(int statId, const wchar_t* name, int enabled) {
	CompareItem it;
	it.statId = statId;
	it.name = WideToUtf8(name);
	it.enabled = enabled != 0;
	g.compareItems.push_back(std::move(it));
}

void D2UI_CALL D2Ui_ShowDiff(int show) {
	g.showDiff = show != 0;
	if (g.showDiff)
		EnsureDiffWindow(true);
	else if (g.diffHwnd)
		ShowWindow(g.diffHwnd, SW_HIDE);
}

void D2UI_CALL D2Ui_ClearDiff() {
	g.diffRows.clear();
}

void D2UI_CALL D2Ui_AddDiffRow(int statId, const wchar_t* name, const wchar_t* oldV, const wchar_t* newV, const wchar_t* diff) {
	DiffRow r;
	r.statId = statId;
	r.name = WideToUtf8(name);
	r.oldV = WideToUtf8(oldV);
	r.newV = WideToUtf8(newV);
	r.diff = WideToUtf8(diff);
	g.diffRows.push_back(std::move(r));
}

void D2UI_CALL D2Ui_SetSpeedCalcCombo(int which, const wchar_t* pipeList, const wchar_t* selected) {
	if (which < 0 || which > 4)
		return;
	g.scCombo[which] = SplitPipe(WideToUtf8(pipeList));
	g.scSelected[which] = WideToUtf8(selected);
}

void D2UI_CALL D2Ui_SetSpeedCalcInput(int which, const wchar_t* value) {
	if (which < 0 || which > 4)
		return;
	g.scInput[which] = WideToUtf8(value);
}

void D2UI_CALL D2Ui_SetSpeedCalcCheck(int which, int checked, int visible) {
	if (which < 0 || which > 1)
		return;
	g.scCheck[which] = checked != 0;
	g.scCheckVisible[which] = visible != 0;
	if (!visible)
		g.scCheck[which] = false;
}

void D2UI_CALL D2Ui_SetSpeedCalcStatus(const wchar_t* status) {
	g.scStatus = WideToUtf8(status);
}

void D2UI_CALL D2Ui_SetSpeedCalcMorphEnabled(int enabled) {
	g.scMorphEnabled = enabled != 0;
}

void D2UI_CALL D2Ui_ClearSpeedCalcTable(int table) {
	if (table < 0 || table > 3)
		return;
	g.scTables[table].rows.clear();
	g.scTables[table].highlight = -1;
}

void D2UI_CALL D2Ui_AddSpeedCalcRow(int table, const wchar_t* frm, const wchar_t* value) {
	if (table < 0 || table > 3)
		return;
	g.scTables[table].rows.emplace_back(WideToUtf8(frm), WideToUtf8(value));
}

void D2UI_CALL D2Ui_SetSpeedCalcHighlight(int table, int row) {
	if (table < 0 || table > 3)
		return;
	g.scTables[table].highlight = row;
}

} // extern "C"
