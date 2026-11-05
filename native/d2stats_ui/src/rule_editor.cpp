#include "rule_editor.h"

// Used to undo the scroll the mouse wheel already applied to the document when
// the pointer is over the completion popup.
#include "imgui_internal.h"

#include <algorithm>
#include <cctype>
#include <cmath>
#include <cstdio>
#include <string>
#include <string_view>
#include <unordered_map>
#include <vector>

namespace d2ui {
namespace {

constexpr float kPadX = 6.0f;
constexpr float kPadY = 3.0f;
constexpr int kMaxCompletions = 80;
constexpr int kMaxCompletionRows = 10;

bool IsWordChar(char c) {
	return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '_';
}

bool IsNameChar(char c) {
	return IsWordChar(c) || c == ' ' || c == '\'' || c == '-';
}

bool IsCompletionTrigger(char c) {
	return IsWordChar(c) || c == '-';
}

bool IsSpaceChar(char c) {
	return c == ' ' || c == '\t';
}

int Utf8SequenceLength(unsigned char c) {
	if (c < 0x80)
		return 1;
	if ((c & 0xE0) == 0xC0)
		return 2;
	if ((c & 0xF0) == 0xE0)
		return 3;
	if ((c & 0xF8) == 0xF0)
		return 4;
	return 1;
}

int PrevChar(const std::string& s, int pos) {
	if (pos <= 0)
		return 0;
	int p = pos - 1;
	while (p > 0 && (static_cast<unsigned char>(s[static_cast<size_t>(p)]) & 0xC0) == 0x80)
		--p;
	return p;
}

int NextChar(const std::string& s, int pos) {
	if (pos >= static_cast<int>(s.size()))
		return static_cast<int>(s.size());
	const int len = Utf8SequenceLength(static_cast<unsigned char>(s[static_cast<size_t>(pos)]));
	return std::min(static_cast<int>(s.size()), pos + len);
}

std::string Lower(std::string s) {
	for (char& c : s)
		c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
	return s;
}

bool StartsWithNoCase(const std::string& text, const std::string& prefix) {
	if (prefix.size() > text.size())
		return false;
	for (size_t i = 0; i < prefix.size(); ++i) {
		if (std::tolower(static_cast<unsigned char>(text[i])) != std::tolower(static_cast<unsigned char>(prefix[i])))
			return false;
	}
	return true;
}

void AppendUtf8(std::string& out, unsigned cp) {
	if (cp < 0x80) {
		out.push_back(static_cast<char>(cp));
	} else if (cp < 0x800) {
		out.push_back(static_cast<char>(0xC0 | (cp >> 6)));
		out.push_back(static_cast<char>(0x80 | (cp & 0x3F)));
	} else if (cp < 0x10000) {
		out.push_back(static_cast<char>(0xE0 | (cp >> 12)));
		out.push_back(static_cast<char>(0x80 | ((cp >> 6) & 0x3F)));
		out.push_back(static_cast<char>(0x80 | (cp & 0x3F)));
	} else {
		out.push_back(static_cast<char>(0xF0 | (cp >> 18)));
		out.push_back(static_cast<char>(0x80 | ((cp >> 12) & 0x3F)));
		out.push_back(static_cast<char>(0x80 | ((cp >> 6) & 0x3F)));
		out.push_back(static_cast<char>(0x80 | (cp & 0x3F)));
	}
}

const char* CompletionCategoryLabel(const std::string& category) {
	if (category == "item")
		return "item";
	if (category == "text")
		return "used";
	return category.c_str();
}

int EditDistance(const std::string& a, const std::string& b) {
	const size_t n = a.size();
	const size_t m = b.size();
	std::vector<int> previous(m + 1);
	std::vector<int> current(m + 1);
	for (size_t j = 0; j <= m; ++j)
		previous[j] = static_cast<int>(j);
	for (size_t i = 1; i <= n; ++i) {
		current[0] = static_cast<int>(i);
		for (size_t j = 1; j <= m; ++j) {
			const int cost = (std::tolower(static_cast<unsigned char>(a[i - 1])) ==
							  std::tolower(static_cast<unsigned char>(b[j - 1])))
								 ? 0
								 : 1;
			current[j] = std::min({previous[j] + 1, current[j - 1] + 1, previous[j - 1] + cost});
		}
		previous.swap(current);
	}
	return previous[m];
}

} // namespace

// ---------------------------------------------------------------------------
// Text and line index
// ---------------------------------------------------------------------------

void RuleEditor::SetText(const std::string& text) {
	std::string normalized;
	normalized.reserve(text.size() + 16);
	for (size_t i = 0; i < text.size(); ++i) {
		const char c = text[i];
		if (c == '\r') {
			if (i + 1 < text.size() && text[i + 1] == '\n')
				continue;
			normalized.push_back('\n');
			continue;
		}
		if (c == '\t') {
			normalized.append(4, ' ');
			continue;
		}
		normalized.push_back(c);
	}
	if (normalized == text_)
		return;

	text_ = std::move(normalized);
	cursor_ = 0;
	anchor_ = -1;
	preferredX_ = -1.0f;
	ensureCaret_ = false;
	folded_.clear(); // a new document starts unfolded
	undo_.clear();
	redo_.clear();
	CloseCompletion();
	RebuildIndex();
}

void RuleEditor::SetKeywords(const std::string& pipeList) {
	keywords_.clear();
	keywordTokens_.clear();

	size_t start = 0;
	while (start <= pipeList.size()) {
		size_t end = pipeList.find('|', start);
		if (end == std::string::npos)
			end = pipeList.size();

		const std::string entry = pipeList.substr(start, end - start);
		const size_t colon = entry.find(':');
		if (colon != std::string::npos && colon + 1 < entry.size()) {
			RuleCompletion completion;
			completion.category = entry.substr(0, colon);
			completion.label = entry.substr(colon + 1);
			keywords_.push_back(completion);

			Token token = Token::Unknown;
			if (completion.category == "tier")
				token = Token::Tier;
			else if (completion.category == "quality")
				token = Token::Quality;
			else if (completion.category == "misc")
				token = Token::Misc;
			else if (completion.category == "socket")
				token = Token::Socket;
			else if (completion.category == "color")
				token = Token::Color;
			else if (completion.category == "sound")
				token = Token::Sound;
			else if (completion.category == "display")
				token = Token::Display;
			keywordTokens_[Lower(completion.label)] = token;
		}

		if (end == pipeList.size())
			break;
		start = end + 1;
	}
}

void RuleEditor::SetItemNames(const std::string& pipeList) {
	items_.clear();
	FillItemNames(pipeList, false);
}

void RuleEditor::AppendItemNames(const std::string& pipeList) {
	FillItemNames(pipeList, true);
}

void RuleEditor::FillItemNames(const std::string& pipeList, bool append) {
	if (!append)
		items_.clear();

	std::unordered_map<std::string, bool> seen;
	for (const auto& item : items_)
		seen[Lower(item.label)] = true;

	size_t start = 0;
	while (start <= pipeList.size()) {
		size_t end = pipeList.find('|', start);
		if (end == std::string::npos)
			end = pipeList.size();
		const std::string name = pipeList.substr(start, end - start);
		if (!name.empty()) {
			const std::string key = Lower(name);
			if (!seen.count(key)) {
				seen[key] = true;
				RuleCompletion completion;
				completion.category = "item";
				completion.label = name;
				items_.push_back(std::move(completion));
			}
		}
		if (end == pipeList.size())
			break;
		start = end + 1;
	}
}

void RuleEditor::RebuildIndex() {
	lineOffsets_.clear();
	lineOffsets_.push_back(0);
	for (size_t i = 0; i < text_.size(); ++i) {
		if (text_[i] == '\n')
			lineOffsets_.push_back(static_cast<unsigned>(i + 1));
	}
	folded_.resize(lineOffsets_.size(), 0);
	cursor_ = ClampPos(cursor_);
	if (anchor_ >= 0)
		anchor_ = ClampPos(anchor_);
	RebuildStructure();
}

void RuleEditor::RebuildStructure() {
	const int lines = LineCount();
	lineDepth_.assign(static_cast<size_t>(lines), 0);
	folded_.resize(static_cast<size_t>(lines), 0);

	int depth = 0;
	for (int line = 0; line < lines; ++line) {
		lineDepth_[static_cast<size_t>(line)] = depth;
		const std::string_view text = LineViewTrimmed(line);
		if (text.empty() || text[0] == '#')
			continue;
		if (depth > 0 && IsGroupCloseLine(line)) {
			depth -= 1;
			lineDepth_[static_cast<size_t>(line)] = depth;
			continue;
		}
		if (IsGroupOpenLine(line))
			depth += 1;
	}

	visible_.clear();
	visible_.reserve(static_cast<size_t>(lines));
	for (int line = 0; line < lines; ++line) {
		visible_.push_back(line);
		if (folded_[static_cast<size_t>(line)]) {
			const int level = lineDepth_[static_cast<size_t>(line)];
			while (line + 1 < lines && lineDepth_[static_cast<size_t>(line + 1)] > level)
				++line;
		}
	}
}

int RuleEditor::LineFromPos(int pos) const {
	if (lineOffsets_.empty())
		return 0;
	pos = std::max(0, pos);
	int lo = 0;
	int hi = static_cast<int>(lineOffsets_.size()) - 1;
	while (lo < hi) {
		const int mid = (lo + hi + 1) / 2;
		if (static_cast<int>(lineOffsets_[static_cast<size_t>(mid)]) <= pos)
			lo = mid;
		else
			hi = mid - 1;
	}
	return lo;
}

int RuleEditor::LineStart(int line) const {
	if (lineOffsets_.empty())
		return 0;
	line = std::max(0, std::min(line, LineCount() - 1));
	return static_cast<int>(lineOffsets_[static_cast<size_t>(line)]);
}

int RuleEditor::LineEnd(int line) const {
	if (line < 0 || line >= LineCount())
		return static_cast<int>(text_.size());
	if (line + 1 < LineCount())
		return std::max(LineStart(line), LineStart(line + 1) - 1);
	return static_cast<int>(text_.size());
}

std::string_view RuleEditor::LineView(int line) const {
	const int begin = LineStart(line);
	const int end = std::max(begin, LineEnd(line));
	return std::string_view(text_.data() + begin, static_cast<size_t>(end - begin));
}

std::string_view RuleEditor::LineViewTrimmed(int line) const {
	int begin = LineStart(line);
	int end = LineEnd(line);
	while (begin < end && IsSpaceChar(text_[static_cast<size_t>(begin)]))
		++begin;
	while (end > begin && IsSpaceChar(text_[static_cast<size_t>(end - 1)]))
		--end;
	return std::string_view(text_.data() + begin, static_cast<size_t>(end - begin));
}

int RuleEditor::ClampPos(int pos) const {
	return std::max(0, std::min(pos, static_cast<int>(text_.size())));
}

bool RuleEditor::InsideUnterminatedString(int pos) const {
	const int line = LineFromPos(pos);
	const int lineStart = LineStart(line);
	const std::string_view text = LineView(line);
	const int index = pos - lineStart;
	if (index <= 0 || index > static_cast<int>(text.size()))
		return false;

	bool inside = false;
	for (int i = 0; i < index; ++i) {
		if (text[static_cast<size_t>(i)] == '"')
			inside = !inside;
	}
	if (!inside)
		return false;

	// A string that already has its closing quote keeps it; only an unterminated
	// one ("Stone of J|) needs the completion to add the quote.
	for (int i = index; i < static_cast<int>(text.size()); ++i) {
		if (text[static_cast<size_t>(i)] == '"')
			return false;
	}
	return true;
}
bool RuleEditor::IsGroupOpenLine(int line) const {
	// Comments are stripped the same way the AutoIt rule compiler strips them,
	// so a trailing "# note" does not hide the opening brace.
	std::string_view text = LineViewTrimmed(line);
	const size_t hash = text.find('#');
	if (hash != std::string_view::npos)
		text = text.substr(0, hash);
	while (!text.empty() && IsSpaceChar(text.back()))
		text.remove_suffix(1);
	if (text.empty() || text.back() != '{')
		return false;
	// A lone "{" opens a group.
	if (text.size() == 1)
		return true;
	// "[flags] {" opens a group. Anything else (a quoted pattern, a stat
	// pattern) is a regular rule line.
	return text[0] == '[' && text.find(']') != std::string_view::npos;
}

bool RuleEditor::IsGroupCloseLine(int line) const {
	// Accept "}", "}", "} ]" and "]}" the same way the rule compiler does, so a
	// closing line that also closes the header brackets is understood.
	std::string_view text = LineViewTrimmed(line);
	const size_t hash = text.find('#');
	if (hash != std::string_view::npos)
		text = text.substr(0, hash);
	bool hasBrace = false;
	for (char c : text) {
		if (c == '}')
			hasBrace = true;
		else if (c != ']' && !IsSpaceChar(c))
			return false;
	}
	return hasBrace;
}

bool RuleEditor::HasFoldMarker(int line) const {
	if (!IsGroupOpenLine(line))
		return false;
	if (line + 1 >= LineCount())
		return false;
	return lineDepth_[static_cast<size_t>(line + 1)] > lineDepth_[static_cast<size_t>(line)];
}

// ---------------------------------------------------------------------------
// Editing
// ---------------------------------------------------------------------------

void RuleEditor::BeginEdit(bool typing) {
	const double now = ImGui::GetTime();
	const bool coalesce = typing && lastEditTyping_ && (now - lastEditTime_) < 0.7 && !undo_.empty();
	lastEditTime_ = now;
	lastEditTyping_ = typing;
	if (coalesce)
		return;

	Snapshot snapshot;
	snapshot.text = text_;
	snapshot.cursor = cursor_;
	snapshot.anchor = anchor_;
	undo_.push_back(std::move(snapshot));
	if (undo_.size() > 256)
		undo_.erase(undo_.begin());
	redo_.clear();
}

void RuleEditor::InsertText(const std::string& insert) {
	if (insert.empty())
		return;
	BeginEdit(true);

	const int from = anchor_ >= 0 ? std::min(anchor_, cursor_) : cursor_;
	const int to = anchor_ >= 0 ? std::max(anchor_, cursor_) : cursor_;
	text_.replace(static_cast<size_t>(from), static_cast<size_t>(to - from), insert);
	cursor_ = from + static_cast<int>(insert.size());
	anchor_ = -1;
	caretBlinkReset_ = ImGui::GetTime();
	ensureCaret_ = true;
	RebuildIndex();
}

void RuleEditor::EraseRange(int from, int to) {
	from = ClampPos(std::min(from, to));
	to = ClampPos(std::max(from, to));
	if (from == to)
		return;
	BeginEdit(false);
	text_.erase(static_cast<size_t>(from), static_cast<size_t>(to - from));
	cursor_ = from;
	anchor_ = -1;
	caretBlinkReset_ = ImGui::GetTime();
	ensureCaret_ = true;
	RebuildIndex();
}

void RuleEditor::DeleteSelection() {
	if (anchor_ < 0 || anchor_ == cursor_)
		return;
	EraseRange(std::min(anchor_, cursor_), std::max(anchor_, cursor_));
}

void RuleEditor::ReplaceRange(int from, int to, const std::string& replacement) {
	from = ClampPos(std::min(from, to));
	to = ClampPos(std::max(from, to));
	BeginEdit(false);
	text_.replace(static_cast<size_t>(from), static_cast<size_t>(to - from), replacement);
	cursor_ = from + static_cast<int>(replacement.size());
	anchor_ = -1;
	caretBlinkReset_ = ImGui::GetTime();
	ensureCaret_ = true;
	RebuildIndex();
}

void RuleEditor::IndentLines(int fromLine, int toLine, bool outdent) {
	BeginEdit(false);
	for (int line = toLine; line >= fromLine; --line) {
		const int lineStart = LineStart(line);
		if (outdent) {
			int remove = 0;
			while (remove < 2 && lineStart + remove < LineEnd(line) && text_[static_cast<size_t>(lineStart + remove)] == ' ')
				++remove;
			if (remove == 0)
				continue;
			text_.erase(static_cast<size_t>(lineStart), static_cast<size_t>(remove));
			if (cursor_ >= lineStart + remove)
				cursor_ -= remove;
			else if (cursor_ > lineStart)
				cursor_ = lineStart;
			if (anchor_ >= lineStart + remove)
				anchor_ -= remove;
			else if (anchor_ > lineStart)
				anchor_ = lineStart;
		} else {
			text_.insert(static_cast<size_t>(lineStart), "  ");
			if (cursor_ >= lineStart)
				cursor_ += 2;
			if (anchor_ >= lineStart)
				anchor_ += 2;
		}
	}
	RebuildIndex();
	ensureCaret_ = true;
	caretBlinkReset_ = ImGui::GetTime();
}

void RuleEditor::Undo() {
	if (undo_.empty())
		return;

	Snapshot current;
	current.text = text_;
	current.cursor = cursor_;
	current.anchor = anchor_;
	redo_.push_back(std::move(current));

	Snapshot snapshot = undo_.back();
	undo_.pop_back();
	text_ = std::move(snapshot.text);
	cursor_ = ClampPos(snapshot.cursor);
	anchor_ = snapshot.anchor >= 0 ? ClampPos(snapshot.anchor) : -1;
	lastEditTyping_ = false;
	lastEditTime_ = -1000.0;
	caretBlinkReset_ = ImGui::GetTime();
	ensureCaret_ = true;
	RebuildIndex();
}

void RuleEditor::Redo() {
	if (redo_.empty())
		return;

	Snapshot current;
	current.text = text_;
	current.cursor = cursor_;
	current.anchor = anchor_;
	undo_.push_back(std::move(current));

	Snapshot snapshot = redo_.back();
	redo_.pop_back();
	text_ = std::move(snapshot.text);
	cursor_ = ClampPos(snapshot.cursor);
	anchor_ = snapshot.anchor >= 0 ? ClampPos(snapshot.anchor) : -1;
	lastEditTyping_ = false;
	lastEditTime_ = -1000.0;
	caretBlinkReset_ = ImGui::GetTime();
	ensureCaret_ = true;
	RebuildIndex();
}

void RuleEditor::SelectAll() {
	anchor_ = 0;
	cursor_ = static_cast<int>(text_.size());
	preferredX_ = -1.0f;
}

void RuleEditor::CopySelection() {
	if (anchor_ < 0 || anchor_ == cursor_)
		return;
	const int from = std::min(anchor_, cursor_);
	const int to = std::max(anchor_, cursor_);
	ImGui::SetClipboardText(text_.substr(static_cast<size_t>(from), static_cast<size_t>(to - from)).c_str());
}

void RuleEditor::CutSelection() {
	if (anchor_ < 0 || anchor_ == cursor_)
		return;
	CopySelection();
	DeleteSelection();
}

void RuleEditor::PasteClipboard() {
	const char* clipboard = ImGui::GetClipboardText();
	if (!clipboard)
		return;
	std::string pasted;
	for (const char* p = clipboard; *p; ++p) {
		if (*p == '\r') {
			if (p[1] == '\n')
				continue;
			pasted.push_back('\n');
			continue;
		}
		if (*p == '\t') {
			pasted.append(4, ' ');
			continue;
		}
		pasted.push_back(*p);
	}
	InsertText(pasted);
}

void RuleEditor::MoveCaret(int pos, bool select) {
	const int old = cursor_;
	cursor_ = ClampPos(pos);
	if (select) {
		if (anchor_ < 0)
			anchor_ = old;
	} else {
		anchor_ = -1;
	}
	preferredX_ = -1.0f;
	caretBlinkReset_ = ImGui::GetTime();
	ensureCaret_ = true;
}

void RuleEditor::MoveCaretWord(int direction, bool select) {
	int pos = cursor_;
	if (direction < 0) {
		while (pos > 0 && IsSpaceChar(text_[static_cast<size_t>(pos - 1)]))
			pos = PrevChar(text_, pos);
		while (pos > 0 && IsWordChar(text_[static_cast<size_t>(pos - 1)]))
			pos = PrevChar(text_, pos);
	} else {
		while (pos < static_cast<int>(text_.size()) && IsWordChar(text_[static_cast<size_t>(pos)]))
			pos = NextChar(text_, pos);
		while (pos < static_cast<int>(text_.size()) && IsSpaceChar(text_[static_cast<size_t>(pos)]))
			pos = NextChar(text_, pos);
	}
	MoveCaret(pos, select);
}

void RuleEditor::MoveCaretVertical(int direction, bool select) {
	const int line = LineFromPos(cursor_);
	if (preferredX_ < 0.0f)
		preferredX_ = MeasureX(line, cursor_);

	int visual = VisualIndexOf(line);
	if (visual < 0) {
		for (int l = line - 1; l >= 0; --l) {
			if (folded_[static_cast<size_t>(l)] && lineDepth_[static_cast<size_t>(l)] < lineDepth_[static_cast<size_t>(line)])
				folded_[static_cast<size_t>(l)] = 0;
		}
		RebuildStructure();
		visual = VisualIndexOf(line);
		if (visual < 0)
			return;
	}

	const int target = visual + direction;
	int pos;
	if (target < 0)
		pos = 0;
	else if (target >= static_cast<int>(visible_.size()))
		pos = static_cast<int>(text_.size());
	else
		pos = PosFromX(visible_[static_cast<size_t>(target)], preferredX_);

	const float keepX = preferredX_;
	MoveCaret(pos, select);
	preferredX_ = keepX;
}

int RuleEditor::VisualIndexOf(int line) const {
	for (int i = 0; i < static_cast<int>(visible_.size()); ++i) {
		if (visible_[static_cast<size_t>(i)] == line)
			return i;
	}
	return -1;
}

// ---------------------------------------------------------------------------
// Layout helpers
// ---------------------------------------------------------------------------

float RuleEditor::LineHeight() const {
	ImFont* font = drawFont_ ? drawFont_ : ImGui::GetFont();
	return std::floor((font ? font->FontSize : 13.0f) + 4.0f);
}

float RuleEditor::MeasureX(int line, int pos) const {
	ImFont* font = drawFont_ ? drawFont_ : ImGui::GetFont();
	if (!font)
		return 0.0f;
	const int begin = LineStart(line);
	const int end = LineEnd(line);
	pos = std::max(begin, std::min(pos, end));
	if (pos <= begin)
		return 0.0f;
	const char* text = text_.c_str();
	return font->CalcTextSizeA(drawFontSize_, FLT_MAX, 0.0f, text + begin, text + pos).x;
}

float RuleEditor::MeasureLineWidth(int line) const {
	return MeasureX(line, LineEnd(line));
}

int RuleEditor::PosFromX(int line, float x) const {
	ImFont* font = drawFont_ ? drawFont_ : ImGui::GetFont();
	const int begin = LineStart(line);
	const int end = LineEnd(line);
	if (!font || x <= 0.0f)
		return begin;

	const char* text = text_.c_str();
	float acc = 0.0f;
	int pos = begin;
	while (pos < end) {
		const int next = NextChar(text_, pos);
		const float width = font->CalcTextSizeA(drawFontSize_, FLT_MAX, 0.0f, text + pos, text + next).x;
		if (acc + width * 0.5f > x)
			break;
		acc += width;
		pos = next;
	}
	return pos;
}

int RuleEditor::PosFromScreen(const ImVec2& screenPos, float textX, float firstLineY, float lineHeight) const {
	const float y = screenPos.y - firstLineY;
	int row = static_cast<int>(std::floor(y / lineHeight));
	if (row < 0)
		row = 0;
	if (row >= static_cast<int>(visible_.size()))
		return static_cast<int>(text_.size());
	const int line = visible_[static_cast<size_t>(row)];
	return PosFromX(line, screenPos.x - textX);
}

// ---------------------------------------------------------------------------
// Syntax
// ---------------------------------------------------------------------------

RuleEditor::Token RuleEditor::ClassifyWord(const std::string& word) const {
	auto it = keywordTokens_.find(Lower(word));
	if (it != keywordTokens_.end())
		return it->second;
	return Token::Unknown;
}

std::string RuleEditor::SuggestKeyword(const std::string& word) const {
	std::string best;
	int bestDistance = 1 << 30;
	for (const auto& completion : keywords_) {
		const int distance = EditDistance(word, completion.label);
		if (distance < bestDistance) {
			bestDistance = distance;
			best = completion.label;
		}
	}
	// Only suggest when the typo is small relative to the keyword.
	const int limit = std::max(1, static_cast<int>(word.size()) / 3);
	if (bestDistance > limit)
		return {};
	return best;
}

void RuleEditor::Tokenize(int line, std::vector<Span>& out) const {
	out.clear();
	const std::string_view text = LineView(line);
	const int size = static_cast<int>(text.size());
	if (size == 0)
		return;

	// A line that only closes a group is a single bracket token.
	{
		int a = 0;
		int b = size;
		while (a < b && IsSpaceChar(text[static_cast<size_t>(a)]))
			++a;
		while (b > a && IsSpaceChar(text[static_cast<size_t>(b - 1)]))
			--b;
		if (b - a == 1 && text[static_cast<size_t>(a)] == '}') {
			out.push_back({a, 1, Token::Bracket});
			return;
		}
	}

	int textStart = -1;
	auto flushText = [&](int end) {
		if (textStart >= 0 && end > textStart)
			out.push_back({textStart, end - textStart, Token::Text});
		textStart = -1;
	};

	int i = 0;
	while (i < size) {
		const char c = text[static_cast<size_t>(i)];

		if (c == '#') {
			flushText(i);
			out.push_back({i, size - i, Token::Comment});
			return;
		}

		if (c == '"') {
			flushText(i);
			int j = i + 1;
			bool escaped = false;
			while (j < size) {
				const char d = text[static_cast<size_t>(j)];
				if (escaped) {
					escaped = false;
				} else if (d == '\\') {
					escaped = true;
				} else if (d == '"') {
					++j;
					break;
				}
				++j;
			}
			out.push_back({i, j - i, Token::String});
			i = j;
			continue;
		}

		if (c == '{') {
			int look = i + 1;
			while (look < size && IsSpaceChar(text[static_cast<size_t>(look)]))
				++look;
			const bool groupOpener = (look >= size || text[static_cast<size_t>(look)] == '#');
			flushText(i);
			if (groupOpener) {
				out.push_back({i, 1, Token::Bracket});
				++i;
				continue;
			}
			int j = i + 1;
			while (j < size && text[static_cast<size_t>(j)] != '}')
				++j;
			if (j < size)
				++j;
			out.push_back({i, j - i, Token::Stat});
			i = j;
			continue;
		}

		if (c == '[' || c == ']' || c == '}') {
			flushText(i);
			out.push_back({i, 1, Token::Bracket});
			++i;
			continue;
		}

		if (IsWordChar(c)) {
			flushText(i);
			int j = i;
			while (j < size && IsWordChar(text[static_cast<size_t>(j)]))
				++j;
			out.push_back({i, j - i, ClassifyWord(std::string(text.substr(static_cast<size_t>(i), static_cast<size_t>(j - i))))});
			i = j;
			continue;
		}

		if (textStart < 0)
			textStart = i;
		++i;
	}
	flushText(size);
}

ImU32 RuleEditor::TokenColor(const Palette& palette, Token token) const {
	switch (token) {
	case Token::Comment:
		return palette.comment;
	case Token::String:
		return palette.string;
	case Token::Stat:
		return palette.stat;
	case Token::Bracket:
		return palette.bracket;
	case Token::Tier:
		return palette.tier;
	case Token::Quality:
		return palette.quality;
	case Token::Misc:
		return palette.misc;
	case Token::Socket:
		return palette.socket;
	case Token::Color:
		return palette.color;
	case Token::Sound:
		return palette.sound;
	case Token::Display:
		return palette.display;
	case Token::Unknown:
		return palette.unknown;
	case Token::Text:
	default:
		return palette.text;
	}
}

RuleEditor::Palette RuleEditor::BuildPalette() const {
	Palette palette{};
	// The editor always paints a near-black surface (see Draw) so the syntax
	// colors stay readable and identical no matter which UI theme is active.
	palette.text = IM_COL32(0xD8, 0xDE, 0xE9, 255);
	palette.selection = IM_COL32(0x2E, 0x53, 0x82, 255);
	palette.currentLine = IM_COL32(0xFF, 0xFF, 0xFF, 0x12);
	palette.caret = IM_COL32(0xE6, 0xE6, 0xE6, 255);
	palette.gutterText = IM_COL32(0x6E, 0x76, 0x81, 255);
	palette.gutterActive = IM_COL32(0xD8, 0xDE, 0xE9, 255);
	palette.gutterMarker = IM_COL32(0x9A, 0xA3, 0xB0, 255);

	// The completion popup follows the active theme, like any other ImGui popup.
	palette.popupBg = ImGui::GetColorU32(ImGuiCol_PopupBg);
	palette.popupBorder = ImGui::GetColorU32(ImGuiCol_Border);
	palette.popupText = ImGui::GetColorU32(ImGuiCol_Text);
	palette.popupSelection = ImGui::GetColorU32(ImGuiCol_HeaderHovered);
	palette.popupDim = ImGui::GetColorU32(ImGuiCol_TextDisabled);

	palette.comment = IM_COL32(0x7D, 0x8A, 0x80, 255);
	palette.string = IM_COL32(0xE0, 0x99, 0x56, 255);
	palette.stat = IM_COL32(0x8F, 0xC0, 0x7F, 255);
	palette.bracket = IM_COL32(0x9A, 0xA8, 0xBA, 255);
	palette.tier = IM_COL32(0xC0, 0x99, 0xFA, 255);
	palette.quality = IM_COL32(0x74, 0xB0, 0xFF, 255);
	palette.misc = IM_COL32(0x5A, 0xD6, 0xB8, 255);
	palette.socket = IM_COL32(0x7F, 0xD9, 0xF2, 255);
	palette.color = IM_COL32(0xE6, 0x7A, 0xA8, 255);
	palette.sound = IM_COL32(0xCE, 0xBE, 0x78, 255);
	palette.display = IM_COL32(0xB4, 0xBC, 0xC8, 255);
	palette.unknown = IM_COL32(0xFF, 0x62, 0x62, 255);
	return palette;
}

// ---------------------------------------------------------------------------
// Completion
// ---------------------------------------------------------------------------

RuleEditor::LineContext RuleEditor::ClassifyPosition(int line, int offset) const {
	LineContext context;
	const std::string_view text = LineView(line);
	offset = std::max(0, std::min(offset, static_cast<int>(text.size())));

	bool inString = false;
	bool inStat = false;
	bool escaped = false;
	for (int i = 0; i < offset; ++i) {
		const char c = text[static_cast<size_t>(i)];
		if (inString) {
			if (escaped)
				escaped = false;
			else if (c == '\\')
				escaped = true;
			else if (c == '"')
				inString = false;
			continue;
		}
		if (inStat) {
			if (c == '}')
				inStat = false;
			continue;
		}
		if (c == '#') {
			context.kind = LineContext::Comment;
			return context;
		}
		if (c == '"')
			inString = true;
		else if (c == '{')
			inStat = true;
	}

	if (inString)
		context.kind = LineContext::String;
	else if (inStat)
		context.kind = LineContext::Stat;
	else
		context.kind = LineContext::Code;
	return context;
}

void RuleEditor::CloseCompletion() {
	completionOpen_ = false;
	completionMatches_.clear();
	completionIndex_ = 0;
	completionOffset_ = 0;
	completionShowAll_ = false;
}

void RuleEditor::OpenCompletion(bool explicitRequest) {
	if (explicitRequest)
		completionShowAll_ = true;

	const int line = LineFromPos(cursor_);
	const int lineOffset = cursor_ - LineStart(line);
	const LineContext context = ClassifyPosition(line, lineOffset);
	const std::string_view text = LineView(line);

	if (context.kind == LineContext::String) {
		// Complete the whole plain-text run so "Stone of J" is replaced as one
		// piece instead of only the last word.
		int start = lineOffset;
		while (start > 0 && IsNameChar(text[static_cast<size_t>(start - 1)]))
			--start;
		completionStart_ = LineStart(line) + start;
	} else if (context.kind == LineContext::Code) {
		int start = lineOffset;
		while (start > 0 && IsWordChar(text[static_cast<size_t>(start - 1)]))
			--start;
		completionStart_ = LineStart(line) + start;
	} else {
		CloseCompletion();
		return;
	}

	completionOpen_ = true;
	completionIndex_ = 0;
	completionOffset_ = 0;

	// An implicit request (typing) with nothing to complete against would list
	// every keyword, which is noise right after a space or a completed flag.
	if (!explicitRequest && cursor_ == completionStart_) {
		CloseCompletion();
		return;
	}

	FilterCompletion();
	if (completionMatches_.empty())
		CloseCompletion();
}

void RuleEditor::FilterCompletion() {
	completionMatches_.clear();

	const int line = LineFromPos(cursor_);
	const LineContext context = ClassifyPosition(line, cursor_ - LineStart(line));
	const std::string query =
		text_.substr(static_cast<size_t>(completionStart_), static_cast<size_t>(std::max(0, cursor_ - completionStart_)));

	auto push = [&](const RuleCompletion& completion) {
		if (StartsWithNoCase(completion.label, query))
			completionMatches_.push_back(completion);
	};

	if (context.kind == LineContext::String) {
		for (const auto& item : items_)
			push(item);
	} else {
		for (const auto& keyword : keywords_)
			push(keyword);
	}

	// De-duplicate labels: an item can be both in the game cache and the document.
	for (size_t i = 0; i < completionMatches_.size(); ++i) {
		for (size_t j = i + 1; j < completionMatches_.size();) {
			if (Lower(completionMatches_[i].label) == Lower(completionMatches_[j].label))
				completionMatches_.erase(completionMatches_.begin() + static_cast<std::ptrdiff_t>(j));
			else
				++j;
		}
	}
	if (static_cast<int>(completionMatches_.size()) > kMaxCompletions)
		completionMatches_.resize(static_cast<size_t>(kMaxCompletions));
	if (completionIndex_ >= static_cast<int>(completionMatches_.size()))
		completionIndex_ = 0;
}

void RuleEditor::AcceptCompletion() {
	if (!completionOpen_ || completionMatches_.empty())
		return;

	const int index = std::max(0, std::min(completionIndex_, static_cast<int>(completionMatches_.size()) - 1));
	const RuleCompletion completion = completionMatches_[static_cast<size_t>(index)];

	std::string insert = completion.label;
	const bool isName = completion.category == "item" || completion.category == "text";
	if (isName) {
		// A name lives in quotes; when the closing quote is not typed yet, the
		// completion adds it so `"Stone of J` becomes `"Stone of Jades"`.
		if (InsideUnterminatedString(completionStart_))
			insert.push_back('"');
	} else {
		insert.push_back(' ');
	}

	ReplaceRange(completionStart_, cursor_, insert);
	CloseCompletion();
}

bool RuleEditor::HandleCompletionKeys() {
	if (!completionOpen_)
		return false;

	const int count = static_cast<int>(completionMatches_.size());
	if (count == 0) {
		CloseCompletion();
		return false;
	}

	auto move = [&](int delta) { completionIndex_ = (completionIndex_ + delta + count) % count; };

	if (ImGui::IsKeyPressed(ImGuiKey_DownArrow, true)) {
		move(1);
		return true;
	}
	if (ImGui::IsKeyPressed(ImGuiKey_UpArrow, true)) {
		move(-1);
		return true;
	}
	if (ImGui::IsKeyPressed(ImGuiKey_PageDown, false)) {
		move(8);
		return true;
	}
	if (ImGui::IsKeyPressed(ImGuiKey_PageUp, false)) {
		move(-8);
		return true;
	}
	if (ImGui::IsKeyPressed(ImGuiKey_Tab, false) || ImGui::IsKeyPressed(ImGuiKey_Enter, false) ||
		ImGui::IsKeyPressed(ImGuiKey_KeypadEnter, false)) {
		AcceptCompletion();
		return true;
	}
	if (ImGui::IsKeyPressed(ImGuiKey_Escape, false)) {
		CloseCompletion();
		return true;
	}
	if (ImGui::IsKeyPressed(ImGuiKey_LeftArrow, true) || ImGui::IsKeyPressed(ImGuiKey_RightArrow, true) ||
		ImGui::IsKeyPressed(ImGuiKey_Home, false) || ImGui::IsKeyPressed(ImGuiKey_End, false)) {
		CloseCompletion();
		return false;
	}
	return false;
}

void RuleEditor::ComputeCompletionRect(float textX, float firstLineY, float lineHeight) {
	completionRect_ = ImVec4(0.0f, 0.0f, 0.0f, 0.0f);
	if (!completionOpen_ || completionMatches_.empty())
		return;

	const int line = LineFromPos(cursor_);
	const int row = VisualIndexOf(line);
	if (row < 0)
		return;

	const float caretX = textX + MeasureX(line, cursor_);
	const float caretY = firstLineY + static_cast<float>(row) * lineHeight;

	float width = 140.0f;
	for (const auto& completion : completionMatches_) {
		float w = drawFont_->CalcTextSizeA(drawFontSize_, FLT_MAX, 0.0f, completion.label.c_str()).x +
				  drawFont_->CalcTextSizeA(drawFontSize_, FLT_MAX, 0.0f, CompletionCategoryLabel(completion.category)).x;
		width = std::max(width, w + 40.0f);
	}
	width = std::min(width, 460.0f);

	const int rows = std::min(static_cast<int>(completionMatches_.size()), kMaxCompletionRows);
	const float height = static_cast<float>(rows) * lineHeight + 4.0f;

	const ImVec2 viewMin = ImGui::GetWindowPos();
	const ImVec2 viewMax = ImVec2(viewMin.x + ImGui::GetWindowSize().x, viewMin.y + ImGui::GetWindowSize().y);

	// Nudge the list to the right so it does not sit on top of the caret / the
	// word being typed.
	const float charWidth = std::max(1.0f, drawFont_->GetCharAdvance('0'));
	const float xOffset = std::max(10.0f, charWidth);

	ImVec2 pos(caretX + xOffset, caretY + lineHeight);
	if (pos.x + width > viewMax.x - 2.0f)
		pos.x = std::max(viewMin.x + 2.0f, viewMax.x - width - 2.0f);
	if (pos.y + height > viewMax.y - 2.0f)
		pos.y = std::max(viewMin.y + 2.0f, caretY - height - 2.0f);

	completionRect_ = ImVec4(pos.x, pos.y, pos.x + width, pos.y + height);
}

void RuleEditor::DrawCompletion(const Palette& palette, float lineHeight) {
	if (!completionOpen_ || completionMatches_.empty())
		return;
	if (completionRect_.z <= completionRect_.x)
		return;

	const ImGuiStyle& style = ImGui::GetStyle();
	ImDrawList* draw = ImGui::GetForegroundDrawList();
	const ImVec2 min(completionRect_.x, completionRect_.y);
	const ImVec2 max(completionRect_.z, completionRect_.w);
	draw->AddRectFilled(min, max, palette.popupBg, style.PopupRounding);
	draw->AddRect(min, max, palette.popupBorder, style.PopupRounding, 0, style.PopupBorderSize);

	const int rows = std::min(static_cast<int>(completionMatches_.size()), kMaxCompletionRows);
	if (completionIndex_ < completionOffset_)
		completionOffset_ = completionIndex_;
	if (completionIndex_ >= completionOffset_ + rows)
		completionOffset_ = completionIndex_ - rows + 1;

	const int total = static_cast<int>(completionMatches_.size());
	const bool scrollable = total > rows;
	const float labelRight = max.x - (scrollable ? 14.0f : 6.0f);

	for (int i = 0; i < rows; ++i) {
		const int index = completionOffset_ + i;
		if (index >= total)
			break;

		const float y = min.y + 2.0f + static_cast<float>(i) * lineHeight;
		if (index == completionIndex_)
			draw->AddRectFilled(ImVec2(min.x + 1.0f, y - 1.0f), ImVec2(max.x - 1.0f, y + lineHeight - 1.0f),
				palette.popupSelection, 2.0f);

		const RuleCompletion& completion = completionMatches_[static_cast<size_t>(index)];
		draw->AddText(drawFont_, drawFontSize_, ImVec2(min.x + 6.0f, y), palette.popupText, completion.label.c_str());

		const char* label = CompletionCategoryLabel(completion.category);
		const float labelWidth = drawFont_->CalcTextSizeA(drawFontSize_, FLT_MAX, 0.0f, label).x;
		draw->AddText(drawFont_, drawFontSize_, ImVec2(labelRight - labelWidth, y), palette.popupDim, label);
	}

	if (scrollable) {
		// Thin scrollbar so it is obvious the list keeps going, in theme colours.
		const float trackTop = min.y + 3.0f;
		const float trackBottom = max.y - 3.0f;
		const float trackHeight = trackBottom - trackTop;
		const float thumbHeight = std::max(12.0f, trackHeight * static_cast<float>(rows) / static_cast<float>(total));
		const float travel = std::max(0.0f, trackHeight - thumbHeight);
		const float offset = static_cast<float>(completionOffset_) / static_cast<float>(total - rows);
		const float thumbTop = trackTop + travel * offset;
		draw->AddRectFilled(ImVec2(max.x - 7.0f, trackTop), ImVec2(max.x - 4.0f, trackBottom),
			ImGui::GetColorU32(ImGuiCol_ScrollbarBg), 1.5f);
		draw->AddRectFilled(ImVec2(max.x - 7.0f, thumbTop), ImVec2(max.x - 4.0f, thumbTop + thumbHeight),
			ImGui::GetColorU32(ImGuiCol_ScrollbarGrab), 1.5f);
	}
}

// ---------------------------------------------------------------------------
// Input
// ---------------------------------------------------------------------------

bool RuleEditor::HandleKeys(bool& changed) {
	ImGuiIO& io = ImGui::GetIO();
	const bool ctrl = io.KeyCtrl;
	const bool shift = io.KeyShift;

	if (ctrl && shift && ImGui::IsKeyPressed(ImGuiKey_Z, false)) {
		Redo();
		changed = true;
		return true;
	}
	if (ctrl && ImGui::IsKeyPressed(ImGuiKey_Z, false)) {
		Undo();
		changed = true;
		return true;
	}
	if (ctrl && ImGui::IsKeyPressed(ImGuiKey_Y, false)) {
		Redo();
		changed = true;
		return true;
	}
	if (ctrl && ImGui::IsKeyPressed(ImGuiKey_A, false)) {
		SelectAll();
		return true;
	}
	if (ctrl && ImGui::IsKeyPressed(ImGuiKey_C, false)) {
		CopySelection();
		return true;
	}
	if (ctrl && ImGui::IsKeyPressed(ImGuiKey_X, false)) {
		CutSelection();
		changed = true;
		return true;
	}
	if (ctrl && ImGui::IsKeyPressed(ImGuiKey_V, false)) {
		PasteClipboard();
		changed = true;
		return true;
	}
	if (ctrl && ImGui::IsKeyPressed(ImGuiKey_S, false)) {
		saveRequested_ = true;
		return true;
	}
	if (ctrl && ImGui::IsKeyPressed(ImGuiKey_Space, false)) {
		io.InputQueueCharacters.resize(0);
		OpenCompletion(true);
		return true;
	}

	const float lineHeight = LineHeight();
	const int visibleRows = std::max(1, static_cast<int>((ImGui::GetWindowHeight() - 2.0f * kPadY) / lineHeight));

	if (ImGui::IsKeyPressed(ImGuiKey_LeftArrow, true)) {
		if (ctrl)
			MoveCaretWord(-1, shift);
		else
			MoveCaret(PrevChar(text_, cursor_), shift);
		return true;
	}
	if (ImGui::IsKeyPressed(ImGuiKey_RightArrow, true)) {
		if (ctrl)
			MoveCaretWord(1, shift);
		else
			MoveCaret(NextChar(text_, cursor_), shift);
		return true;
	}
	if (ImGui::IsKeyPressed(ImGuiKey_UpArrow, true)) {
		MoveCaretVertical(-1, shift);
		return true;
	}
	if (ImGui::IsKeyPressed(ImGuiKey_DownArrow, true)) {
		MoveCaretVertical(1, shift);
		return true;
	}
	if (ImGui::IsKeyPressed(ImGuiKey_PageUp, false)) {
		MoveCaretVertical(-visibleRows, shift);
		return true;
	}
	if (ImGui::IsKeyPressed(ImGuiKey_PageDown, false)) {
		MoveCaretVertical(visibleRows, shift);
		return true;
	}
	if (ImGui::IsKeyPressed(ImGuiKey_Home, false)) {
		const int line = LineFromPos(cursor_);
		int pos = ctrl ? 0 : LineStart(line);
		if (!ctrl) {
			int firstNonSpace = pos;
			while (firstNonSpace < LineEnd(line) && IsSpaceChar(text_[static_cast<size_t>(firstNonSpace)]))
				++firstNonSpace;
			if (cursor_ != firstNonSpace)
				pos = firstNonSpace;
		}
		MoveCaret(pos, shift);
		return true;
	}
	if (ImGui::IsKeyPressed(ImGuiKey_End, false)) {
		MoveCaret(ctrl ? static_cast<int>(text_.size()) : LineEnd(LineFromPos(cursor_)), shift);
		return true;
	}
	if (ImGui::IsKeyPressed(ImGuiKey_Backspace, true)) {
		if (anchor_ >= 0 && anchor_ != cursor_)
			DeleteSelection();
		else if (cursor_ > 0)
			EraseRange(PrevChar(text_, cursor_), cursor_);
		changed = true;
		if (completionOpen_)
			OpenCompletion(completionShowAll_);
		return true;
	}
	if (ImGui::IsKeyPressed(ImGuiKey_Delete, true)) {
		if (anchor_ >= 0 && anchor_ != cursor_)
			DeleteSelection();
		else if (cursor_ < static_cast<int>(text_.size()))
			EraseRange(cursor_, NextChar(text_, cursor_));
		changed = true;
		if (completionOpen_)
			OpenCompletion(completionShowAll_);
		return true;
	}
	if (ImGui::IsKeyPressed(ImGuiKey_Enter, false) || ImGui::IsKeyPressed(ImGuiKey_KeypadEnter, false)) {
		// Plain newline: no automatic indentation, the user decides the layout.
		InsertText("\n");
		changed = true;
		CloseCompletion();
		return true;
	}
	if (ImGui::IsKeyPressed(ImGuiKey_Tab, false)) {
		if (anchor_ >= 0 && anchor_ != cursor_ && LineFromPos(anchor_) != LineFromPos(cursor_)) {
			IndentLines(std::min(LineFromPos(anchor_), LineFromPos(cursor_)), std::max(LineFromPos(anchor_), LineFromPos(cursor_)),
				shift);
			changed = true;
		} else if (shift) {
			const int line = LineFromPos(cursor_);
			IndentLines(line, line, true);
			changed = true;
		} else {
			InsertText("  ");
			changed = true;
		}
		return true;
	}
	if (ImGui::IsKeyPressed(ImGuiKey_Escape, false)) {
		if (anchor_ >= 0) {
			anchor_ = -1;
			return true;
		}
		return false;
	}
	return false;
}

void RuleEditor::HandleTextInput(bool& changed) {
	ImGuiIO& io = ImGui::GetIO();
	if (io.InputQueueCharacters.Size == 0)
		return;

	std::string input;
	for (int i = 0; i < io.InputQueueCharacters.Size; ++i) {
		const unsigned codepoint = static_cast<unsigned>(io.InputQueueCharacters[i]);
		if (codepoint < 32 || codepoint == 127)
			continue;
		AppendUtf8(input, codepoint);
	}
	io.InputQueueCharacters.resize(0);
	if (input.empty())
		return;

	InsertText(input);
	changed = true;

	const char last = input.back();
	const int line = LineFromPos(cursor_);
	const bool nameContext = ClassifyPosition(line, cursor_ - LineStart(line)).kind == LineContext::String;
	if (completionOpen_) {
		if (IsCompletionTrigger(last) || (nameContext && IsNameChar(last)))
			OpenCompletion(completionShowAll_);
		else
			CloseCompletion();
	} else if (IsCompletionTrigger(last)) {
		OpenCompletion(false);
	}
}

// ---------------------------------------------------------------------------
// Draw
// ---------------------------------------------------------------------------

bool RuleEditor::Draw(const char* id, ImFont* font, const ImVec2& size, bool* saveRequested) {
	if (saveRequested)
		*saveRequested = false;

	if (!font)
		font = ImGui::GetFont();
	if (lineOffsets_.empty())
		RebuildIndex();
	if (static_cast<int>(lineDepth_.size()) != LineCount())
		RebuildStructure();
	drawFont_ = font;
	drawFontSize_ = font ? font->FontSize : ImGui::GetFontSize();

	const Palette palette = BuildPalette();
	const float lineHeight = LineHeight();
	const float charWidth = std::max(1.0f, drawFont_->GetCharAdvance('0'));

	int digits = 2;
	for (int value = LineCount(); value >= 10; value /= 10)
		++digits;
	const float gutterWidth = std::floor(charWidth * static_cast<float>(digits) + 14.0f);

	float maxLineWidth = 0.0f;
	for (int line = 0; line < LineCount(); ++line)
		maxLineWidth = std::max(maxLineWidth, MeasureLineWidth(line));

	// The rule editor is always a near-black surface: the syntax colors were
	// picked against it and it reads better than tinted theme backgrounds.
	const ImVec4 surface(0.106f, 0.114f, 0.133f, 1.0f);

	bool changed = false;
	ImGui::PushStyleVar(ImGuiStyleVar_WindowPadding, ImVec2(0.0f, 0.0f));
	ImGui::PushStyleVar(ImGuiStyleVar_ItemSpacing, ImVec2(0.0f, 0.0f));
	ImGui::PushStyleColor(ImGuiCol_ChildBg, surface);
	ImGui::PushStyleColor(ImGuiCol_Border, IM_COL32(0x33, 0x38, 0x40, 255));
	ImGui::PushStyleColor(ImGuiCol_ScrollbarBg, IM_COL32(0x1B, 0x1D, 0x22, 255));
	ImGui::PushStyleColor(ImGuiCol_ScrollbarGrab, IM_COL32(0x39, 0x3F, 0x48, 255));
	ImGui::PushStyleColor(ImGuiCol_ScrollbarGrabHovered, IM_COL32(0x4A, 0x51, 0x5C, 255));
	ImGui::PushStyleColor(ImGuiCol_ScrollbarGrabActive, IM_COL32(0x5A, 0x62, 0x6E, 255));

	ImGui::BeginChild(id, size, ImGuiChildFlags_Borders, ImGuiWindowFlags_HorizontalScrollbar);
	{
		const ImVec2 windowPos = ImGui::GetWindowPos();
		const ImVec2 windowSize = ImGui::GetWindowSize();
		float scrollX = ImGui::GetScrollX();
		float scrollY = ImGui::GetScrollY();
		const ImVec2 textAreaMin(windowPos.x + gutterWidth, windowPos.y);
		const ImVec2 textAreaMax(windowPos.x + windowSize.x, windowPos.y + windowSize.y);

		const float contentWidth = gutterWidth + kPadX * 2.0f + maxLineWidth + 12.0f;
		const float contentHeight = static_cast<float>(visible_.size()) * lineHeight + kPadY * 2.0f;
		ImGui::SetCursorPos(ImVec2(0.0f, 0.0f));
		ImGui::Dummy(ImVec2(std::max(contentWidth, windowSize.x), std::max(contentHeight, windowSize.y)));

		float firstLineY = windowPos.y + kPadY - scrollY;
		float textX = windowPos.x + gutterWidth + kPadX - scrollX;

		ImGuiIO& io = ImGui::GetIO();
		bool focused = ImGui::IsWindowFocused();
		const bool hovered = ImGui::IsWindowHovered(ImGuiHoveredFlags_ChildWindows);

		if (hovered && ImGui::IsMouseClicked(0)) {
			ImGui::SetWindowFocus();
			focused = true;
		}

		// Scrolling over the completion popup walks the list instead of moving
		// the document underneath it.
		if (completionOpen_ && io.MouseWheel != 0.0f) {
			const ImVec2 mouse = io.MousePos;
			if (mouse.x >= completionRect_.x && mouse.x <= completionRect_.z && mouse.y >= completionRect_.y &&
				mouse.y <= completionRect_.w) {
				// ImGui already applied the wheel to the child in NewFrame().
				ImGuiWindow* current = ImGui::GetCurrentWindow();
				current->Scroll.x = lastScrollX_;
				current->Scroll.y = lastScrollY_;
				current->ScrollTarget = ImVec2(FLT_MAX, FLT_MAX);
				scrollX = lastScrollX_;
				scrollY = lastScrollY_;
				firstLineY = windowPos.y + kPadY - scrollY;
				textX = windowPos.x + gutterWidth + kPadX - scrollX;

				const int rows = std::min(static_cast<int>(completionMatches_.size()), kMaxCompletionRows);
				const int maxOffset = std::max(0, static_cast<int>(completionMatches_.size()) - rows);
				const int step = static_cast<int>(std::lround(io.MouseWheel)) * 3;
				completionOffset_ = std::max(0, std::min(maxOffset, completionOffset_ - step));
				// Keep the highlighted entry inside the visible window.
				const int lastVisible = std::min(static_cast<int>(completionMatches_.size()) - 1, completionOffset_ + rows - 1);
				completionIndex_ = std::max(completionOffset_, std::min(completionIndex_, lastVisible));
			}
		}

		ComputeCompletionRect(textX, firstLineY, lineHeight);

		// --- mouse --------------------------------------------------------
		if (ImGui::IsMouseClicked(0)) {
			const ImVec2 mouse = io.MousePos;
			const bool overCompletion = completionOpen_ && mouse.x >= completionRect_.x && mouse.x <= completionRect_.z &&
										mouse.y >= completionRect_.y && mouse.y <= completionRect_.w;
			if (overCompletion) {
				const int row = static_cast<int>(std::floor((mouse.y - completionRect_.y - 2.0f) / lineHeight));
				const int index = completionOffset_ + row;
				if (row >= 0 && index < static_cast<int>(completionMatches_.size())) {
					completionIndex_ = index;
					AcceptCompletion();
					changed = true;
				}
			} else if (hovered && mouse.x >= windowPos.x && mouse.x < windowPos.x + gutterWidth) {
				const int row = static_cast<int>(std::floor((mouse.y - firstLineY) / lineHeight));
				if (row >= 0 && row < static_cast<int>(visible_.size())) {
					const int line = visible_[static_cast<size_t>(row)];
					if (HasFoldMarker(line)) {
						folded_[static_cast<size_t>(line)] = folded_[static_cast<size_t>(line)] ? 0 : 1;
						RebuildStructure();
					}
				}
			} else if (hovered) {
				const int pos = PosFromScreen(mouse, textX, firstLineY, lineHeight);
				const int oldCursor = cursor_;
				cursor_ = pos;
				anchor_ = io.KeyShift ? (anchor_ >= 0 ? anchor_ : oldCursor) : pos;
				dragging_ = 1;
				preferredX_ = -1.0f;
				caretBlinkReset_ = ImGui::GetTime();
				ensureCaret_ = false;
				CloseCompletion();
			}
		}
		if (dragging_ && ImGui::IsMouseDown(0) && ImGui::IsMouseDragging(0)) {
			cursor_ = PosFromScreen(io.MousePos, textX, firstLineY, lineHeight);
			caretBlinkReset_ = ImGui::GetTime();
		}
		if (!ImGui::IsMouseDown(0)) {
			dragging_ = 0;
			if (anchor_ == cursor_)
				anchor_ = -1;
		}
		if (hovered && !completionOpen_ && ImGui::IsMouseDoubleClicked(0)) {
			const int pos = PosFromScreen(io.MousePos, textX, firstLineY, lineHeight);
			const int line = LineFromPos(pos);
			int from = pos;
			int to = pos;
			const int lineStart = LineStart(line);
			const int lineEnd = LineEnd(line);
			while (from > lineStart && IsWordChar(text_[static_cast<size_t>(from - 1)]))
				--from;
			while (to < lineEnd && IsWordChar(text_[static_cast<size_t>(to)]))
				++to;
			anchor_ = from;
			cursor_ = to;
		}

		// --- keyboard -----------------------------------------------------
		if (navDefault_ < 0)
			navDefault_ = (io.ConfigFlags & ImGuiConfigFlags_NavEnableKeyboard) ? 1 : 0;
		if (focused) {
			io.ConfigFlags &= ~ImGuiConfigFlags_NavEnableKeyboard;
			bool consumed = false;
			if (completionOpen_)
				consumed = HandleCompletionKeys();
			if (!consumed) {
				HandleKeys(changed);
				HandleTextInput(changed);
			}
			io.ConfigFlags &= ~ImGuiConfigFlags_NavEnableKeyboard;
		} else if (navDefault_) {
			io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;
		}

		// --- keep the caret in view ---------------------------------------
		if (ensureCaret_) {
			ensureCaret_ = false;
			const int line = LineFromPos(cursor_);
			int visual = VisualIndexOf(line);
			if (visual < 0) {
				for (int l = line - 1; l >= 0; --l) {
					if (folded_[static_cast<size_t>(l)] && lineDepth_[static_cast<size_t>(l)] < lineDepth_[static_cast<size_t>(line)])
						folded_[static_cast<size_t>(l)] = 0;
				}
				RebuildStructure();
				visual = VisualIndexOf(line);
			}
			if (visual >= 0) {
				const float top = static_cast<float>(visual) * lineHeight;
				const float bottom = top + lineHeight;
				const float viewTop = ImGui::GetScrollY();
				const float viewHeight = windowSize.y;
				if (top < viewTop)
					ImGui::SetScrollY(top);
				else if (bottom > viewTop + viewHeight)
					ImGui::SetScrollY(bottom - viewHeight);

				const float caretX = MeasureX(line, cursor_) + kPadX;
				const float viewLeft = ImGui::GetScrollX();
				const float viewRight = viewLeft + windowSize.x - gutterWidth;
				if (caretX < viewLeft)
					ImGui::SetScrollX(std::max(0.0f, caretX - 8.0f));
				else if (caretX + 2.0f > viewRight)
					ImGui::SetScrollX(caretX + 16.0f - windowSize.x + gutterWidth);
			}
		}

		// --- painting -----------------------------------------------------
		// Scrolling may have changed above; re-read it so text, caret and the
		// completion popup are laid out against the scroll offset of this frame.
		scrollX = ImGui::GetScrollX();
		scrollY = ImGui::GetScrollY();
		firstLineY = windowPos.y + kPadY - scrollY;
		textX = windowPos.x + gutterWidth + kPadX - scrollX;
		ComputeCompletionRect(textX, firstLineY, lineHeight);

		ImDrawList* draw = ImGui::GetWindowDrawList();
		draw->PushClipRect(windowPos, ImVec2(windowPos.x + windowSize.x, windowPos.y + windowSize.y), true);

		draw->AddRectFilled(windowPos, ImVec2(windowPos.x + gutterWidth, windowPos.y + windowSize.y), IM_COL32(0x16, 0x18, 0x1C, 255));

		const bool hasSelection = anchor_ >= 0 && anchor_ != cursor_;
		const int selectionFrom = hasSelection ? std::min(anchor_, cursor_) : -1;
		const int selectionTo = hasSelection ? std::max(anchor_, cursor_) : -1;
		const int caretLine = LineFromPos(cursor_);

		// Which token is the mouse over? Used for the "unknown keyword" tooltip.
		int hoverLine = -1;
		int hoverColumn = -1;
		if (hovered && !dragging_ && !completionOpen_ && io.MousePos.x >= textAreaMin.x) {
			const int row = static_cast<int>(std::floor((io.MousePos.y - firstLineY) / lineHeight));
			if (row >= 0 && row < static_cast<int>(visible_.size())) {
				hoverLine = visible_[static_cast<size_t>(row)];
				hoverColumn = PosFromX(hoverLine, io.MousePos.x - textX) - LineStart(hoverLine);
			}
		}

		std::vector<Span> spans;
		draw->PushClipRect(textAreaMin, textAreaMax, true);
		for (int row = 0; row < static_cast<int>(visible_.size()); ++row) {
			const float y = firstLineY + static_cast<float>(row) * lineHeight;
			if (y + lineHeight < windowPos.y)
				continue;
			if (y > windowPos.y + windowSize.y)
				break;

			const int line = visible_[static_cast<size_t>(row)];

			if (focused && line == caretLine)
				draw->AddRectFilled(ImVec2(textAreaMin.x, y), ImVec2(textAreaMax.x, y + lineHeight), palette.currentLine);

			if (hasSelection && selectionFrom <= LineEnd(line) && selectionTo >= LineStart(line)) {
				const int a = std::max(selectionFrom, LineStart(line));
				const int b = std::min(selectionTo, LineEnd(line));
				float x0 = textX + MeasureX(line, a);
				float x1 = textX + MeasureX(line, b);
				if (selectionTo > LineEnd(line))
					x1 += charWidth * 0.5f;
				if (x1 < x0 + 1.0f)
					x1 = x0 + 1.0f;
				draw->AddRectFilled(ImVec2(x0, y), ImVec2(x1, y + lineHeight), palette.selection);
			}

			Tokenize(line, spans);
			float x = textX;
			for (const Span& span : spans) {
				const char* start = text_.c_str() + LineStart(line) + span.start;
				const char* end = start + span.length;
				const ImU32 color = TokenColor(palette, span.token);
				draw->AddText(drawFont_, drawFontSize_, ImVec2(x, y), color, start, end);
				const float width = drawFont_->CalcTextSizeA(drawFontSize_, FLT_MAX, 0.0f, start, end).x;
				if (span.token == Token::Unknown) {
					// Dotted underline for unknown keywords.
					for (float dash = x; dash < x + width; dash += 3.0f)
						draw->AddLine(ImVec2(dash, y + lineHeight - 2.0f), ImVec2(std::min(dash + 1.5f, x + width), y + lineHeight - 2.0f), color);

					if (line == hoverLine && hoverColumn >= span.start && hoverColumn < span.start + span.length) {
						const std::string word = std::string(text_.substr(static_cast<size_t>(LineStart(line) + span.start),
							static_cast<size_t>(span.length)));
						const std::string suggestion = SuggestKeyword(word);

						// Drawn at a readable size: the editor font is small, and the
						// tooltip inherits whatever font the window uses.
						ImGui::BeginTooltip();
						ImGui::SetWindowFontScale(1.35f);
						ImGui::Text("Unknown keyword '%s'", word.c_str());
						if (!suggestion.empty())
							ImGui::Text("Did you mean '%s'?", suggestion.c_str());
						else
							ImGui::TextUnformatted("This word is not a notifier flag.");
						ImGui::EndTooltip();
					}
				}
				x += width;
			}

			if (focused && line == caretLine && std::fmod(ImGui::GetTime() - caretBlinkReset_, 1.0) < 0.6) {
				const float caretX = textX + MeasureX(line, cursor_);
				draw->AddLine(ImVec2(caretX, y + 1.0f), ImVec2(caretX, y + lineHeight - 1.0f), palette.caret, 1.5f);
			}
		}
		draw->PopClipRect();

		// Gutter contents stay outside of the horizontally scrolling area.
		for (int row = 0; row < static_cast<int>(visible_.size()); ++row) {
			const float y = firstLineY + static_cast<float>(row) * lineHeight;
			if (y + lineHeight < windowPos.y)
				continue;
			if (y > windowPos.y + windowSize.y)
				break;

			const int line = visible_[static_cast<size_t>(row)];
			char number[16];
			snprintf(number, sizeof(number), "%d", line + 1);
			const float numberWidth = drawFont_->CalcTextSizeA(drawFontSize_, FLT_MAX, 0.0f, number).x;
			draw->AddText(drawFont_, drawFontSize_, ImVec2(windowPos.x + gutterWidth - numberWidth - 5.0f, y),
				focused && line == caretLine ? palette.gutterActive : palette.gutterText, number);

			if (HasFoldMarker(line)) {
				const char* marker = folded_[static_cast<size_t>(line)] ? "+" : "-";
				draw->AddText(drawFont_, drawFontSize_, ImVec2(windowPos.x + 3.0f, y), palette.gutterMarker, marker);
			}
		}
		draw->PopClipRect();

		lastScrollX_ = ImGui::GetScrollX();
		lastScrollY_ = ImGui::GetScrollY();
	}
	ImGui::EndChild();
	ImGui::PopStyleColor(6);
	ImGui::PopStyleVar(2);

	DrawCompletion(palette, lineHeight);

	if (saveRequested && saveRequested_)
		*saveRequested = true;
	saveRequested_ = false;

	return changed;
}

} // namespace d2ui
