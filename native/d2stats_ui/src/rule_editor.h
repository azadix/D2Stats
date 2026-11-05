#pragma once

#include "imgui.h"

#include <string>
#include <string_view>
#include <unordered_map>
#include <vector>

namespace d2ui {

// One entry of the rule editor completion popup ("sacred", "unique", "Ring", ...).
struct RuleCompletion {
	std::string label;
	std::string category; // tier, quality, misc, color, sound, display, item, text
};

// Multiline editor for the notifier rule list. Unlike ImGui::InputTextMultiline
// it draws the text itself, which buys syntax highlighting, a keyword / item
// name completion popup and group awareness for the "[flags] { ... }" syntax.
class RuleEditor {
public:
	// Copies the text into the editor, normalizes line endings and resets the
	// undo history.
	void SetText(const std::string& text);
	const std::string& GetText() const { return text_; }

	// "category:keyword|category:keyword|..." as built by NotifierKeywordList().
	void SetKeywords(const std::string& pipeList);
	// Item base type / unique names offered inside quoted patterns.
	void SetItemNames(const std::string& pipeList);
	// Appends to the item name list (rule files and the in-game cache are
	// separate sources).
	void AppendItemNames(const std::string& pipeList);

	// Draws the editor into the current window. Returns true when the text was
	// modified this frame; `saveRequested` is set when Ctrl+S was pressed.
	bool Draw(const char* id, ImFont* font, const ImVec2& size, bool* saveRequested);

	// Number of lines currently rendered (folded groups are collapsed), valid
	// after the first Draw.
	int VisibleLineCount() const { return static_cast<int>(visible_.size()); }

private:
	enum class Token {
		Text,
		Comment,
		String,
		Stat,
		Bracket,
		Tier,
		Quality,
		Misc,
		Socket,
		Color,
		Sound,
		Display,
		Unknown
	};

	struct Span {
		int start = 0;
		int length = 0;
		Token token = Token::Text;
	};

	struct Snapshot {
		std::string text;
		int cursor = 0;
		int anchor = -1;
	};

	struct Palette {
		ImU32 text, comment, string, stat, bracket, tier, quality, misc, socket, color, sound, display, unknown;
		ImU32 selection, currentLine, caret, gutterText, gutterActive, gutterMarker;
		ImU32 popupBg, popupBorder, popupText, popupSelection, popupDim;
	};

	struct LineContext {
		enum Kind { Code, String, Stat, Comment } kind = Code;
	};

	// Text / line index -------------------------------------------------------
	void RebuildIndex();
	void RebuildStructure();
	void UpdateDocumentItems();
	int LineCount() const { return static_cast<int>(lineOffsets_.size()); }
	int LineFromPos(int pos) const;
	int LineStart(int line) const;
	int LineEnd(int line) const; // excludes the '\n'
	std::string_view LineView(int line) const;
	std::string_view LineViewTrimmed(int line) const;
	int ClampPos(int pos) const;
	bool IsGroupOpenLine(int line) const;
	bool IsGroupCloseLine(int line) const;
	bool HasFoldMarker(int line) const;
	int VisualIndexOf(int line) const;

	// Editing -----------------------------------------------------------------
	void BeginEdit(bool typing);
	void InsertText(const std::string& text);
	void EraseRange(int from, int to);
	void DeleteSelection();
	void ReplaceRange(int from, int to, const std::string& text);
	void IndentLines(int fromLine, int toLine, bool outdent);
	void Undo();
	void Redo();
	void SelectAll();
	void CopySelection();
	void CutSelection();
	void PasteClipboard();
	void MoveCaret(int pos, bool select);
	void MoveCaretVertical(int direction, bool select);
	void MoveCaretWord(int direction, bool select);

	// Layout ------------------------------------------------------------------
	float LineHeight() const;
	float MeasureX(int line, int pos) const;
	float MeasureLineWidth(int line) const;
	int PosFromX(int line, float x) const;
	int PosFromScreen(const ImVec2& screenPos, float textX, float firstLineY, float lineHeight) const;

	// Syntax ------------------------------------------------------------------
	void Tokenize(int line, std::vector<Span>& out) const;
	Token ClassifyWord(const std::string& word) const;
	ImU32 TokenColor(const Palette& palette, Token token) const;
	Palette BuildPalette() const;
	std::string SuggestKeyword(const std::string& word) const;
	void FillItemNames(const std::string& pipeList, bool append);

	// Completion --------------------------------------------------------------
	LineContext ClassifyPosition(int line, int offset) const;
	void OpenCompletion(bool explicitRequest);
	void CloseCompletion();
	void FilterCompletion();
	bool HandleCompletionKeys();
	void AcceptCompletion();
	void ComputeCompletionRect(float textX, float firstLineY, float lineHeight);
	void DrawCompletion(const Palette& palette, float lineHeight);

	// Input -------------------------------------------------------------------
	bool HandleKeys(bool& changed);
	void HandleTextInput(bool& changed);

	// State -------------------------------------------------------------------
	std::string text_;
	std::vector<unsigned> lineOffsets_;
	std::vector<int> lineDepth_;
	std::vector<unsigned char> folded_;
	std::vector<int> visible_;

	int cursor_ = 0;
	int anchor_ = -1;
	float preferredX_ = -1.0f;
	bool ensureCaret_ = true;
	double caretBlinkReset_ = 0.0;
	int dragging_ = 0;
	bool saveRequested_ = false;
	int navDefault_ = -1;

	ImFont* drawFont_ = nullptr;
	float drawFontSize_ = 0.0f;

	std::vector<RuleCompletion> keywords_;
	std::unordered_map<std::string, Token> keywordTokens_;
	std::vector<RuleCompletion> items_;
	std::vector<RuleCompletion> documentItems_;
	bool documentItemsDirty_ = true;

	bool completionOpen_ = false;
	bool completionShowAll_ = false;
	int completionStart_ = 0;
	int completionIndex_ = 0;
	int completionOffset_ = 0;
	std::vector<RuleCompletion> completionMatches_;
	ImVec4 completionRect_{0.0f, 0.0f, 0.0f, 0.0f};
	float lastScrollX_ = 0.0f;
	float lastScrollY_ = 0.0f;

	std::vector<Snapshot> undo_;
	std::vector<Snapshot> redo_;
	double lastEditTime_ = -1000.0;
	bool lastEditTyping_ = false;
};

} // namespace d2ui
