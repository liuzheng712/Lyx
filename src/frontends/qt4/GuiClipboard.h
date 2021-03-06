// -*- C++ -*-
/**
 * \file GuiClipboard.h
 * This file is part of LyX, the document processor.
 * Licence details can be found in the file COPYING.
 *
 * \author unknown
 * \author John Levon
 * \author Abdelrazak Younes
 *
 * Full author contact details are available in file CREDITS.
 */

#ifndef GUICLIPBOARD_H
#define GUICLIPBOARD_H

#include "frontends/Clipboard.h"

#include <QObject>

namespace lyx {
namespace frontend {

class QMacPasteboardMimeGraphics;

/**
 * The Qt4 version of the Clipboard.
 */
class GuiClipboard: public QObject, public Clipboard
{
	Q_OBJECT
public:
	GuiClipboard();

	/** Clipboard overloaded methods
	 */
	//@{
	std::string const getAsLyX() const;
	FileName getAsGraphics(Cursor const & cur, GraphicsType type) const;
	docstring const getAsText() const;
	void put(std::string const & lyx, docstring const & text);
	bool hasLyXContents() const;
	bool hasGraphicsContents(GraphicsType type = AnyGraphicsType) const;
	bool hasTextContents() const;
	bool isInternal() const;
	bool hasInternal() const;
	bool empty() const;
	//@}

	FileName getPastedGraphicsFileName(Cursor const & cur,
		Clipboard::GraphicsType & type) const;

private Q_SLOTS:
	void on_dataChanged();

private:
	bool text_clipboard_empty_;
	bool has_lyx_contents_;
	bool has_graphics_contents_;
};

QString const lyxMimeType();
QString const pdfMimeType();
QString const emfMimeType();
QString const wmfMimeType();

} // namespace frontend
} // namespace lyx

#endif // GUICLIPBOARD_H
