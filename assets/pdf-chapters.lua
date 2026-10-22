-- Keep the individual-topic PDFs in sync with the full book's chapter pages.
function Header(header)
  if FORMAT:match("latex") and header.level == 1 then
    local key = header.identifier:gsub("[^A-Za-z0-9_-]", "")
    return {header, pandoc.RawBlock("latex", "\\CoursePDFPage{" .. key .. "}")}
  end
end

-- The datatype table needs a wide description column for its inline R vectors.
function Table(tbl)
  if not FORMAT:match("latex") or #tbl.colspecs ~= 3 or #tbl.head.rows == 0 then
    return nil
  end
  local cells = tbl.head.rows[1].cells
  if pandoc.utils.stringify(cells[1].contents) == "Datatype"
      and pandoc.utils.stringify(cells[3].contents) == "Beskrivelse" then
    tbl.colspecs = {
      {pandoc.AlignLeft, 0.18},
      {pandoc.AlignLeft, 0.22},
      {pandoc.AlignLeft, 0.60}
    }
    return tbl
  end
end
