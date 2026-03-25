> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# Print & Export A4 Colors - Testing Guide ✅

**Quick Start**: Open dispatch detail page, test print and PDF export functionality.

---

## 🎯 Quick Test (5 minutes)

### Test 1: Print Colors

```
1. Open: http://localhost:4200/dispatch/9915
2. Click: 🖨️ Print button
3. Verify:
   ✓ Status badge shows color (yellow/green/red/blue)
   ✓ "Delivery Note" header visible
   ✓ All text readable (dark gray on white)
   ✓ Table headers are BLUE
   ✓ Table has alternating row colors
   ✓ Trip info cards visible (3 columns)
```

### Test 2: PDF Export

```
1. Open: http://localhost:4200/dispatch/9915
2. Click: 📄 Export PDF button
3. Verify:
   ✓ File downloads as "trip-details-[code].pdf"
   ✓ Open in PDF reader
   ✓ Status badge color matches print
   ✓ Blue table headers
   ✓ All text visible and readable
```

---

## 📋 Full Test Suite (15 minutes)

### Test Group 1: Print Preview Colors

**Status Badges - Verify correct colors in print preview**

| Status | Expected Color | Test Dispatch | ✓/✗ |
|--------|----------------|---------------|-----|
| PENDING | 🟡 Yellow (#ca8a04) | Find one | — |
| DELIVERED | 🟢 Green (#16a34a) | Find one | — |
| CANCELLED | 🔴 Red (#dc2626) | Find one | — |
| IN_PROGRESS | 🔵 Blue (#2563eb) | Find one | — |

**Table Colors**

| Element | Expected | Test | ✓/✗ |
|---------|----------|------|-----|
| Headers | 🔵 Blue (#2563eb) | Check table header | — |
| Header Text | ⚪ White | Should be white | — |
| Even Rows | 🩶 Light Gray (#f9fafb) | Check alternating | — |
| Odd Rows | ⚪ White | Check alternating | — |

**Text Colors**

| Text Type | Expected Color | Test | ✓/✗ |
|-----------|----------------|------|-----|
| Body | ⚫ Gray-800 (#1f2937) | All paragraphs | — |
| Labels | ⚫ Gray-600 (#4b5563) | "Trip ID:", "Start:" | — |
| Links | 🔵 Blue (#2563eb) | Phone numbers | — |

---

### Test Group 2: PDF Export Colors

**Open PDF and verify**

```
Step 1: Export to PDF
- Click "Export PDF" button
- File downloads as "trip-details-[code].pdf"

Step 2: Open PDF in Adobe Reader
- Check colors match print preview
- Verify no color bleeding
- Check text is readable

Step 3: Verify Elements
□ Status badge correct color
□ Headers blue with white text
□ Body text dark gray
□ Backgrounds light gray
□ All data visible
□ Images display correctly
```

---

### Test Group 3: A4 Layout Verification

**Print Settings**

```
Paper Size: A4 (210 x 297 mm)
Orientation: Portrait
Margins: 10mm (all sides)
Scale: 100%
Background Graphics: ✓ ON

Expected Output:
- Content area: 190mm x 277mm
- No text cutoff
- Proper spacing
- Multiple pages if needed
```

---

### Test Group 4: Cross-Browser Testing

**Chrome**
```
1. Open dispatch detail
2. Press Ctrl+P (Cmd+P on Mac)
3. In print dialog:
   - Check: "Background graphics" ✓
   - Scale: 100%
4. Click "Preview"
5. Verify:
   ✓ Colors show correctly
   ✓ Layout proper
   ✓ All text visible
```

**Firefox**
```
1. Open dispatch detail
2. Press Ctrl+P (Cmd+P on Mac)
3. In print dialog:
   - Check: "Print backgrounds" ✓
   - Scale: 100%
4. Click "Print to File" (save as PDF)
5. Verify:
   ✓ Colors preserved
   ✓ Same layout as Chrome
```

**Safari** (macOS only)
```
1. Open dispatch detail
2. Press Cmd+P
3. In print dialog:
   - Ensure "Background graphics" enabled
4. Click "Preview"
5. Verify colors and layout
```

---

### Test Group 5: Multi-Page Documents

**Test with dispatch that generates multiple pages**

```
1. Find dispatch with many items (>20)
2. Click "Print"
3. Verify:
   □ Page 1 shows header and content
   □ Page 2 shows table header AGAIN (not cut off)
   □ No rows split between pages
   □ Page numbers visible
   □ Last page complete
```

---

### Test Group 6: Different Status Values

**Create test cases for each status**

| Status | Color | Test Case |
|--------|-------|-----------|
| PENDING | Yellow | Find/Create PENDING dispatch |
| DELIVERED | Green | Find/Create DELIVERED dispatch |
| CANCELLED | Red | Find/Create CANCELLED dispatch |
| IN_PROGRESS | Blue | Find/Create IN_PROGRESS dispatch |
| COMPLETED | Green | Find/Create COMPLETED dispatch |

**Steps**:
1. Open each dispatch detail page
2. Click "Print"
3. Verify status badge color matches expected
4. Click "Export PDF"
5. Verify PDF shows same color

---

### Test Group 7: Edge Cases

**Empty Fields**
```
Dispatch with missing data:
□ Empty driver name → Shows "-"
□ No images → Fallback image shows
□ No timeline → Section still formatted
□ No items → Table header still shows
```

**Large Data**
```
Dispatch with lots of data:
□ Many items (>50) → Spans multiple pages
□ Long addresses → Text wraps properly
□ Large images → Scale correctly
□ Long item names → No cutoff
```

**Special Characters**
```
Dispatch with special characters:
□ Accented letters (é, ñ, etc.) → Display correctly
□ Symbols (®, ™, etc.) → Show in PDF
□ Numbers → Align properly in tables
```

---

## Verification Checklist

### Before Deployment

- [ ] **Print Colors Working**
  - [ ] Status badge shows correct color
  - [ ] Table headers blue
  - [ ] Text readable

- [ ] **PDF Export Working**
  - [ ] File downloads successfully
  - [ ] PDF opens in reader
  - [ ] Colors match print preview

- [ ] **Layout Correct**
  - [ ] A4 paper size
  - [ ] 10mm margins
  - [ ] Content doesn't overflow
  - [ ] Multi-page support works

- [ ] **Cross-Browser Compatible**
  - [ ] Chrome: ✓ Pass
  - [ ] Firefox: ✓ Pass
  - [ ] Safari: ✓ Pass
  - [ ] Edge: ✓ Pass

- [ ] **Data Integrity**
  - [ ] All fields display correctly
  - [ ] Numbers format properly
  - [ ] Dates show correctly
  - [ ] Images load properly

---

## 🔍 Troubleshooting

### Issue: Colors Not Showing in Print

**Solution**:
1. In print dialog, ensure "Background graphics" is ✓ checked
2. Set scale to 100%
3. Try different PDF viewer
4. Check browser supports `print-color-adjust`

### Issue: PDF Shows Gray Headers Instead of Blue

**Cause**: PDF generation not using color theme  
**Solution**: Already fixed in code. Try:
1. Clear browser cache (Ctrl+Shift+Delete)
2. Hard refresh page (Ctrl+F5)
3. Try exporting again

### Issue: Text Hard to Read

**Check**:
- Is "Background graphics" enabled?
- Are colors actually showing?
- Try different PDF viewer

### Issue: Table Cut Off on Page

**Solution**:
- Ensure scale is 100%
- Try landscape orientation
- Check margins are correct (10mm)

### Issue: Status Badge Not Colored in PDF

**Cause**: Status not in color mapping  
**Solution**:
1. Check dispatch.status value
2. Ensure status is in TAILWIND_COLORS.statusColors
3. Verify PDF reader supports colors

---

## 📊 Expected Results

### Print Output

```
┌─────────────────────────────────────┐
│ Delivery Note        🟡 PENDING     │
├─────────────────────────────────────┤
│                                     │
│ Trip Info    Timing    Driver       │
│ ┌───────┐  ┌───────┐  ┌──────────┐ │
│ │Trip..│  │Start..│  │Name...   │ │
│ └───────┘  └───────┘  └──────────┘ │
│                                     │
│ Order Items                         │
│ ┌─────────────────────────────────┐ │
│ │# Code  Name   Type Qty UOM      │ │ ← Blue header
│ ├─────────────────────────────────┤ │
│ │1 SKU1  Item1  BOX  10  pcs      │ │ ← White background
│ │2 SKU2  Item2  BOX  20  pcs      │ │ ← Gray background
│ │3 SKU3  Item3  BOX  15  pcs      │ │ ← White background
│ └─────────────────────────────────┘ │
│                                     │
│ Page 1 of 1                         │
└─────────────────────────────────────┘
```

### PDF Output

```
Exact same as print preview
- Same colors
- Same layout
- Same data
- Same page format
```

---

## 🚀 Sign-Off

When all tests pass:

```
✓ Print functionality verified
✓ PDF export verified
✓ Colors match between print and export
✓ A4 layout correct
✓ Cross-browser tested
✓ Ready for production
```

**Status**: READY TO DEPLOY ✅

---

## Quick Reference

### Print & Export Keyboard Shortcuts

| Action | Windows/Linux | macOS |
|--------|---------------|-------|
| Print | Ctrl+P | Cmd+P |
| Export PDF | Click button | Click button |
| Save PDF | Ctrl+S | Cmd+S |
| Zoom | Ctrl++ | Cmd++ |

### File Naming

```
Exported PDFs named: trip-details-[ROUTE_CODE].pdf
Example: trip-details-RT-20250123-001.pdf
```

### Color Quick Reference

```
Status Colors:
🟡 Yellow (Pending): #ca8a04
🟢 Green (Delivered): #16a34a
🔴 Red (Cancelled): #dc2626
🔵 Blue (In Progress): #2563eb

Theme Colors:
⚫ Text: #1f2937
🩶 Card BG: #f9fafb
⚪ White: #ffffff
```

---

**Ready to test! 🧪**

