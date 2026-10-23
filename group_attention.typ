#set document(title: "Group Attention")
#set page(width: auto, height: auto, margin: 8pt, fill: white)
#set text(font: ("Libertinus Serif", "New Computer Modern"), size: 9.5pt)

#let tum = rgb("#0065BD")
#let tum-dark = rgb("#005293")
#let tum-pale = rgb("#DAE3EE")
#let grey = rgb("#6B6B6B")
#let grey-pale = rgb("#EDEDED")

// ---------- primitives (all coordinates in cm, y downwards) ----------
#let P(x, y, body) = place(top + left, dx: x * 1cm, dy: y * 1cm, body)
#let R(cx, cy, w, h, fill: none, stroke: none, radius: 2.5pt) = P(cx - w / 2, cy - h / 2,
  rect(width: w * 1cm, height: h * 1cm, fill: fill, stroke: stroke, radius: radius))
#let T(cx, cy, body, w: 5, h: 1) = P(cx - w / 2, cy - h / 2,
  box(width: w * 1cm, height: h * 1cm, align(center + horizon, body)))
#let arrow(pts, col: grey, th: 1pt, head: 0.16) = {
  let n = pts.len()
  let (xa, ya) = pts.at(n - 2)
  let (xb, yb) = pts.at(n - 1)
  let l = calc.sqrt(calc.pow(xb - xa, 2) + calc.pow(yb - ya, 2))
  let (ux, uy) = ((xb - xa) / l, (yb - ya) / l)
  let bx = xb - ux * head * 1.6
  let by = yb - uy * head * 1.6
  let body = pts.slice(0, n - 1) + ((bx, by),)
  place(top + left, curve(stroke: (paint: col, thickness: th),
    curve.move((body.at(0).at(0) * 1cm, body.at(0).at(1) * 1cm)),
    ..body.slice(1).map(p => curve.line((p.at(0) * 1cm, p.at(1) * 1cm)))))
  place(top + left, polygon(fill: col,
    (xb * 1cm, yb * 1cm),
    ((bx - uy * head) * 1cm, (by + ux * head) * 1cm),
    ((bx + uy * head) * 1cm, (by - ux * head) * 1cm)))
}

// ---------- model of the example ----------
#let B = 5
#let grp = (0, 0, 0, 1, 1)                       // group id of every series
#let gname = ("A", "B")
#let gcol = (tum, grey)
#let gpale = (tum-pale, grey-pale)
#let sel = 1                                     // highlighted query (series 2)
#let att = (                                     // softmax weights (rows sum to 1)
  (0.50, 0.30, 0.20, 0, 0),
  (0.25, 0.50, 0.25, 0, 0),
  (0.20, 0.30, 0.50, 0, 0),
  (0, 0, 0, 0.65, 0.35),
  (0, 0, 0, 0.40, 0.60),
)

// layout
#let p = 0.9            // row / column pitch
#let Y0 = 3.85          // centre of row 0
#let ry(r) = Y0 + r * p
#let Gx = 3.1           // input grid
#let gcx = (Gx + 0.5, Gx + 1.5, Gx + 2.5, Gx + 3.5)   // 1, 2, dots, n
#let splitx = 7.7
#let Qx = 9.2           // centre of Q column
#let Mx = 10.8          // left edge of score matrix
#let mx(j) = Mx + p / 2 + j * p
#let Mend = Mx + B * p
#let Vx = Mend + 1.5    // centre of V column
#let Ox = Vx + 2.1      // centre of O column
#let W = Ox + 1.0
#let ky = 2.1           // centre of K row
#let yb = ry(B - 1) + 0.9
#let vec-w = 1.2
#let vec-h = 0.72

#box(width: W * 1cm, height: 10.3 * 1cm, {
  // group bands (rows keep their group everywhere)
  for g in (0, 1) {
    let rs = range(B).filter(r => grp.at(r) == g)
    let y0 = ry(rs.first()) - p / 2
    let y1 = ry(rs.last()) + p / 2
    P(0.05, y0 + 0.03, rect(width: (W - 0.1) * 1cm, height: (y1 - y0 - 0.06) * 1cm, radius: 4pt,
      fill: gpale.at(g).lighten(35%), stroke: (paint: gcol.at(g), thickness: 0.7pt, dash: "dashed")))
    T(0.75, (y0 + y1) / 2, text(fill: gcol.at(g), weight: "bold", size: 9pt)[Group #gname.at(g)], w: 1.4)
  }

  // ===== (1) input patch embeddings =====
  T(Gx + 2, 0.75, text(weight: "bold")[Patch embeddings $bold(H)$ (columns = patch index)], w: 7)
  T(Gx + 2, 1.2, text(size: 8pt, fill: grey)[$B$ series #sym.times $N$ patches], w: 7)
  for r in range(B) {
    T(2.05, ry(r), text(size: 8.5pt)[series #(r + 1)], w: 1.8)
    for (ci, cx) in gcx.enumerate() {
      if ci == 2 {
        T(cx, ry(r), text(fill: grey)[$dots.h$], w: 0.8)
      } else {
        let on = ci == 3
        R(cx, ry(r), 0.82, vec-h, radius: 3pt,
          fill: if on { gcol.at(grp.at(r)) } else { gcol.at(grp.at(r)).lighten(65%) },
          stroke: (paint: gcol.at(grp.at(r)), thickness: 0.8pt))
      }
    }
  }
  for (ci, lab) in ((0, [$1$]), (1, [$2$]), (3, [$n$])).map(x => x) {
    T(gcx.at(ci), Y0 - 0.62, text(size: 8.5pt, weight: if ci == 3 { "bold" } else { "regular" },
      fill: if ci == 3 { tum-dark } else { grey })[#lab], w: 1.2)
  }
  // highlight of the sliced column
  R(gcx.at(3), (ry(0) + ry(B - 1)) / 2, 1.1, B * p - 0.05, radius: 4pt,
    stroke: (paint: tum-dark, thickness: 1.8pt))
  T(Gx + 1.5, ry(B - 1) + 0.75, text(size: 8pt, fill: grey)[columns are not mixed here], w: 4.5)

  // ===== slice -> Q, K, V =====
  let ymid = ry(2)
  arrow(((gcx.at(3) + 0.58, ymid), (splitx, ymid)), col: tum-dark, th: 1.3pt, head: 0.0001)
  P(splitx - 0.04, ky - 0.04, rect(width: 0.08 * 1cm, height: (yb - ky + 0.08) * 1cm, fill: tum-dark, stroke: none))
  arrow(((splitx, ymid), (Qx - vec-w / 2 - 0.12, ymid)), col: tum-dark, th: 1.3pt)
  arrow(((splitx, ky), (mx(0) - p / 2 - 0.12, ky)), col: tum-dark, th: 1.3pt)
  arrow(((splitx, yb), (Vx, yb), (Vx, ry(B - 1) + vec-h / 2 + 0.12)), col: tum-dark, th: 1.3pt)
  T((splitx + Qx - vec-w / 2) / 2 + 0.05, ymid + 0.3, text(size: 8.5pt, fill: tum-dark)[$W_Q$], w: 1)
  T((splitx + mx(0) - p / 2) / 2 + 0.2, ky - 0.28, text(size: 8.5pt, fill: tum-dark)[$W_K$], w: 1)
  T((splitx + Vx) / 2, yb - 0.28, text(size: 8.5pt, fill: tum-dark)[$W_V$], w: 1)

  // ===== queries =====
  T(Qx, Y0 - 0.85, text(weight: "bold")[Queries $bold(Q)$], w: 2.2)
  for r in range(B) {
    let on = r == sel
    R(Qx, ry(r), vec-w, vec-h, radius: 3pt,
      fill: gcol.at(grp.at(r)).lighten(if on { 25% } else { 65% }),
      stroke: (paint: if on { tum-dark } else { gcol.at(grp.at(r)) }, thickness: if on { 1.8pt } else { 0.8pt }))
    T(Qx, ry(r), text(size: 8.5pt)[$q_#(r + 1)$], w: 1)
  }

  // ===== keys (row) and group ids =====
  T(Mend + 1.35, ky, text(weight: "bold")[Keys $bold(K)^top$], w: 2.2)
  T(Mx - 0.35, 0.95, text(size: 8.5pt, fill: grey)[group IDs $g$], w: 2.2)
  for j in range(B) {
    let on = grp.at(j) == grp.at(sel)
    R(mx(j), ky, 0.82, 0.9, radius: 3pt,
      fill: gcol.at(grp.at(j)).lighten(if on { 25% } else { 65% }),
      stroke: (paint: if on { tum-dark } else { gcol.at(grp.at(j)) }, thickness: if on { 1.8pt } else { 0.8pt }))
    T(mx(j), ky, text(size: 8.5pt)[$k_#(j + 1)$], w: 0.8)
    R(mx(j), 0.95, 0.5, 0.36, radius: 8pt, fill: gcol.at(grp.at(j)))
    T(mx(j), 0.95, text(size: 7.5pt, fill: white, weight: "bold")[#gname.at(grp.at(j))], w: 0.5, h: 0.4)
  }

  // ===== attention matrix =====
  T(Mx + B * p / 2, Y0 - 0.85, text(weight: "bold")[Attention weights $bold(A)$ ($B times B$)], w: 5.5)
  for i in range(B) {
    for j in range(B) {
      let same = grp.at(i) == grp.at(j)
      let w = att.at(i).at(j)
      let c = gcol.at(grp.at(i))
      R(mx(j), ry(i), p - 0.06, p - 0.06, radius: 2pt,
        fill: if same { c.lighten(calc.round((1 - w) * 88) * 1%) } else { white },
        stroke: if same { (paint: c, thickness: 0.6pt) } else { (paint: rgb("#D0D0D0"), thickness: 0.5pt, dash: "dotted") })
      T(mx(j), ry(i), text(size: 8pt, fill: if same and w >= 0.5 { white } else if same { black } else { rgb("#B0B0B0") },
        if same { str(w) } else { [0] }), w: 0.8)
    }
  }
  // selected query row: outline row in A + matching keys
  R(Mx + B * p / 2, ry(sel), B * p + 0.02, p, radius: 3pt, stroke: (paint: tum-dark, thickness: 1.8pt))
  R(Qx, ry(sel), vec-w + 0.2, p - 0.05, radius: 4pt, stroke: none)

  // ===== × V = O =====
  T(Mend + 0.45, ry(2), text(size: 14pt, fill: grey)[$times$], w: 0.6)
  T(Vx, Y0 - 0.85, text(weight: "bold")[Values $bold(V)$], w: 2.2)
  T(Vx + 1.05, ry(2), text(size: 14pt, fill: grey)[$=$], w: 0.6)
  T(Ox, Y0 - 0.85, text(weight: "bold")[Output $bold(O)$], w: 2.2)
  for r in range(B) {
    let on = grp.at(r) == grp.at(sel)
    R(Vx, ry(r), vec-w, vec-h, radius: 3pt,
      fill: gcol.at(grp.at(r)).lighten(if on { 25% } else { 65% }),
      stroke: (paint: if on { tum-dark } else { gcol.at(grp.at(r)) }, thickness: if on { 1.8pt } else { 0.8pt }))
    T(Vx, ry(r), text(size: 8.5pt)[$v_#(r + 1)$], w: 1)
    let o = r == sel
    R(Ox, ry(r), vec-w, vec-h, radius: 3pt,
      fill: gcol.at(grp.at(r)).lighten(if o { 25% } else { 65% }),
      stroke: (paint: if o { tum-dark } else { gcol.at(grp.at(r)) }, thickness: if o { 1.8pt } else { 0.8pt }))
    T(Ox, ry(r), text(size: 8.5pt)[$o_#(r + 1)$], w: 1)
  }

  // ===== captions =====
  T(W / 2, yb + 0.85, [$bold(A) = op("softmax")(bold(Q) bold(K)^top slash sqrt(d) + bold(M))$, #h(0.6em) $M_(i j) = 0$ if $g_i = g_j$, else $-infinity$ #h(0.6em) #sym.arrow.r #h(0.6em) $o_i = sum_(j : g_j = g_i) A_(i j) v_j$], w: W - 0.4)
  T(W / 2, yb + 1.55, text(size: 8.5pt, fill: grey)[Applied independently for every patch index $n$. Each query attends only to keys of its own group, itself included, and never across groups (weight 0). No positional embedding: series in a group are unordered.], w: W - 0.4)
})
