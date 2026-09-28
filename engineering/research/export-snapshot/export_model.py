# Reference model of DataExportService.exportGrow, used to write the expected
# lines in DataExportTests.swift (no Swift toolchain in this environment).
# Mirrors the Swift code line by line, including NSString padding (which
# truncates longer strings) and String(format: "%.Nf") rounding.

def pad(s, n):
    # NSString.padding(toLength:withPad:startingAt:) truncates or pads (UTF-16 length;
    # all strings here are BMP, so len() == UTF-16 length).
    return s[:n] if len(s) >= n else s + " " * (n - len(s))

def fmt(v, d):
    return "%.*f" % (max(0, min(d, 10)), v)

def water(liters, unit="L"):
    if unit == "L":
        return f"{fmt(liters, 2)} L"
    if unit == "mL":
        return f"{fmt(liters * 1000.0, 0)} mL"
    return f"{fmt(liters / 3.785411784, 2)} gal"

def percent(v):
    return f"{fmt(v, 1)}%"

def temperature(c):
    return f"{fmt(c, 1)} °C"

def interval(h):
    if h >= 24.0:
        whole_days = int(h / 24.0)
        import math
        rem = int(math.fmod(h, 24.0))
        return f"{whole_days}d {rem}h" if rem > 0 else f"{whole_days}d"
    if h >= 1.0:
        return f"{fmt(h, 1)} h"
    minutes = h * 60.0
    if minutes >= 1.0:
        return f"{fmt(minutes, 0)} min"
    return f"{fmt(max(1.0, h * 3600.0), 0)} sec"

def log(water_added, runoff, date, temp=None, hum=None, interval_h=None, photo=False):
    w = max(water_added, 0.001)
    r = max(runoff, 0)
    return dict(water=w, runoff=r, date=date, temp=temp, hum=hum, interval=interval_h,
                retained=max(0, w - r), runoff_pct=min((r / w) * 100.0, 100.0) if w > 0 else 0,
                photo=photo)

def export(grow, now, photo_format):
    lines = []
    divider = "─" * 60
    lines += ["Evapotrack Data Export", f"Generated: {now}", "", f"Grow: {grow['name']}",
              f"Created: {grow['created']}", f"Plants: {len(grow['plants'])}", "", divider]
    plants = sorted(grow["plants"], key=lambda p: p["name"].lower())
    total_logs = 0
    total_photos = 0
    for p in plants:
        lines += ["", f"Plant: {p['name']}", f"  Pot Size: {p['pot']}", f"  Medium: {p['medium']}",
                  f"  Max Retention: {water(p['mrc'])}", f"  Goal Runoff: {percent(p['goal'])}",
                  f"  Created: {p['created']}", f"  Watering Logs: {len(p['logs'])}"]
        logs = sorted(p["logs"], key=lambda l: l["date"], reverse=True)
        total_logs += len(logs)
        if logs:
            has_temp = any(l["temp"] is not None for l in logs)
            has_hum = any(l["hum"] is not None for l in logs)
            has_photo = photo_format and any(l["photo"] for l in logs)
            total_photos += sum(1 for l in logs if l["photo"]) if photo_format else 0
            lines.append("")
            header = "  " + pad("Date", 22) + pad("Water Added", 14) + pad("Runoff", 12) + pad("Retained", 12) + pad("Runoff%", 10) + pad("Interval", 10)
            if has_temp:
                header += pad("Temp", 10)
            if has_hum:
                header += pad("Humidity", 10) if has_photo else "Humidity"
            if has_photo:
                header += "Photo"
            lines.append(header)
            width = 95 if (has_temp or has_hum) else 80
            if has_photo:
                width += 10
            lines.append("  " + "─" * width)
            for l in logs:
                line = "  " + pad(l["date"], 22) + pad(water(l["water"]), 14) + pad(water(l["runoff"]), 12) + pad(water(l["retained"]), 12) + pad(percent(l["runoff_pct"]), 10)
                line += pad(interval(l["interval"]) if l["interval"] is not None else "—", 10)
                if has_temp:
                    line += pad(temperature(l["temp"]) if l["temp"] is not None else "—", 10)
                if has_hum:
                    h = percent(l["hum"]) if l["hum"] is not None else "—"
                    line += pad(h, 10) if has_photo else h
                if has_photo:
                    line += "Yes" if l["photo"] else "—"
                lines.append(line)
        lines += ["", divider]
    if not plants:
        lines += ["", "No plants in this grow.", "", divider]
    n = len(plants)
    lines += ["", f"Total: {n} plant{'' if n == 1 else 's'}, {total_logs} watering log{'' if total_logs == 1 else 's'}"]
    if photo_format and total_photos > 0:
        lines += ["", f"Photos: {total_photos} watering log{'' if total_photos == 1 else 's'} {'has' if total_photos == 1 else 'have'} a photo. Photos stay on this device and are not included in this export."]
    return lines

def fixture(with_photo):
    return dict(
        name="Tent A", created="2026-03-01 00:00",
        plants=[
            dict(name="Basil", pot="Fabric 3 gal", medium="soil", mrc=1.5, goal=15.0, created="2026-03-01 00:05",
                 logs=[log(1.0, 0.2, "2026-03-02 08:00", temp=22.5, hum=60.0, photo=with_photo),
                       log(1.2, 0.3, "2026-03-04 10:15", interval_h=50.25)]),
            dict(name="Aloe", pot="Plastic 1 gal", medium="coco", mrc=0.8, goal=20.0, created="2026-03-01 00:10", logs=[]),
            dict(name="Cactus", pot="Clay 6 in", medium="gritty mix", mrc=0.4, goal=10.0, created="2026-03-01 00:15",
                 logs=[log(0.5, 0.0, "2026-03-03 09:00")]),
        ])

def swift_array(lines, indent="            "):
    out = []
    for l in lines:
        esc = l.replace("\\", "\\\\").replace('"', '\\"')
        out.append(f'{indent}"{esc}",')
    return "\n".join(out)

if __name__ == "__main__":
    import sys
    which = sys.argv[1] if len(sys.argv) > 1 else "old"
    if which == "old":
        print(swift_array(export(fixture(False), "2026-03-10 12:00", photo_format=False)))
    elif which == "new-nophoto":
        print(swift_array(export(fixture(False), "2026-03-10 12:00", photo_format=True)))
    else:
        print(swift_array(export(fixture(True), "2026-03-10 12:00", photo_format=True)))
