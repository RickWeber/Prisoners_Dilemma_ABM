;turtles-own [strategy history memory-length wealth meta-history]
extensions [rnd]
turtles-own [strategy
  partner-history
  history
  memory-length
  wealth
  mutations
  average-wealth
]

to setup
  clear-all
  crt population [
    setxy random-xcor random-ycor
    set memory-length 1
    set strategy random-strategy memory-length
    set history n-values memory-length [ifelse-value assume-cooperation? [1][0]]
    set partner-history []
  ]
  reset-ticks
end

to go
  ask turtles [
    play-n-rounds 200 (rnd:weighted-one-of other turtles [1 / (distance myself + 0.01)])
    set wealth max (list (wealth - (memory-length * cost-of-memory)) 0)
    set average-wealth (0.9 * average-wealth) + (0.1 * wealth)
    risk-mutation
  ]
  if random-float 1 < wildcard-finetune / (10 * wildcard-p-magnitude) [
    ask one-of turtles [
      set strategy random-strategy memory-length
      setxy random-xcor random-ycor
    ]
  ]
  if update-visuals? [
    recolor
  ]
  if rounds-per-GA-event > 0 [ ; if it's set to 0, turn it off.
    if (ticks mod rounds-per-GA-event = 0) [genetic-algorithm]
  ]
  tick
end

to recolor
  ask turtles with [memory-length = 1 ][ set color green ]
  ask turtles with [memory-length = 2 ][ set color blue ]
  ask turtles with [memory-length = 3 ][ set color yellow ]
  ask turtles with [memory-length = 4 ][ set color red ]
  ask turtles with [memory-length > 4 ][ set color grey ]
  ask turtles [set size 1 + mean strategy]
end

to genetic-algorithm
  let turnover-count turnover-rate * population
  ask rnd:weighted-n-of turnover-count turtles [abs wealth] [
    hatch 1 [
      rt random 90
      fd 1
    ]
  ]
    ask rnd:weighted-n-of turnover-count turtles [abs (1 / (wealth + 0.01))] [die]
    ask turtles [ set wealth 0 ]
end

to risk-mutation
  if point-p-magnitude > 0 [
  if random-float 1 < point-finetune / (10 * point-p-magnitude) [
    point-mutate
    set mutations mutations + 1
  ]]
  if split-p-magnitude > 0 [
  if (random-float 1 < split-finetune / (10 * split-p-magnitude)) and memory-length > 1 [
    split-mutate
    set mutations mutations + 1
  ]]
  if duplication-p-magnitude > 0 [
  if random-float 1 < duplication-finetune / (10 * duplication-p-magnitude) [
    duplicate-mutate
    set mutations mutations + 1
  ]]
;  set memory-length log length strategy 2

end

to play-n-rounds [ n partner ]
  repeat n [
    let my-move move-error make-move strategy (trimmed-history memory-length history) ; do I need []?
    let partner-move move-error make-move [strategy] of partner (trimmed-history [memory-length] of partner [history] of partner)
    set history fput partner-move fput my-move history
    let my-payoff ifelse-value (my-move = 1) [
      ifelse-value (partner-move = 1) [win-win-payout][lose-win-payout]
    ][
      ifelse-value (partner-move = 1) [win-lose-payout][lose-lose-payout]
    ]
    let partner-payoff ifelse-value (partner-move = 1) [
      ifelse-value (my-move = 1) [win-win-payout][lose-win-payout]
    ][
      ifelse-value (my-move = 1) [win-lose-payout][lose-lose-payout]
    ]
    set wealth wealth + (my-payoff / n)
    ask partner [
      set history fput my-move fput partner-move history
      set wealth wealth + (partner-payoff / n)
    ]
  ]
  set partner-history fput (list partner n) partner-history
  ask partner [ set partner-history fput (list myself n) partner-history ]
end


;;;;;;;;;;;;;
; Mutations ;
;;;;;;;;;;;;;

to point-mutate
  let i random length strategy
  let Xi item i strategy
  set strategy replace-item i strategy (abs (Xi - 1))
end

to split-mutate
  set strategy ifelse-value random-float 1 < 0.5 [first-half strategy][second-half strategy]
  set memory-length memory-length - 1
  set history sublist history 0 memory-length
end

to duplicate-mutate
  set strategy sentence strategy strategy
  set memory-length memory-length + 1
  set history fput (ifelse-value assume-cooperation? [1][0]) history
end

;;;;;;;;;;;;;
; Reporters ;
;;;;;;;;;;;;;

to-report trimmed-history [ mem-length hist ]
  report sublist hist 0 mem-length
end

to-report binary-to-decimal [ lst ]
  if length lst < 1 [report 0]
  report reduce + (map [[l b] -> l * b] lst (map [b -> 2 ^ b] reverse range length lst))
end

to-report random-strategy [ mem-length ]
  report n-values (2 ^ mem-length) [(ifelse-value (random-float 1 < 0.5) [1][0])]
end

to-report move-error [ move ]
  report ifelse-value (random-float 1 < error-finetune / (10 ^ err-p-magnitude )) [ move ] [ abs (move - 1) ]
end

to-report make-move [ strat hist ]
  let s binary-to-decimal hist
  report item s strat
end

to-report first-half [ lst ]
  let n length lst
  let h n / 2
  report sublist lst 0 h
end

to-report second-half [ lst ]
  let n length lst
  let h n / 2
  report sublist lst h n
end

to-report padded-hist [ initial-hist padding ]
  if padding < 0 [
    report sublist initial-hist 0 (length initial-hist + padding)
  ]
  report reduce sentence list initial-hist n-values padding [1]
end

to-report most-common-strategy [ rank ]
  report most-common-item ([strategy] of turtles) rank
end

to-report most-common-item [ lst rank ]
  if rank = 1 [ report modes lst ]
  ; remove modes
  report most-common-item (filter [l -> not member? l modes lst] lst) (rank - 1)
end

to-report strategy-count
  let all-strategies [strategy] of turtles
  let unique-strategies remove-duplicates all-strategies
  let strategy-counts map [this-strategy -> length filter [B -> B = this-strategy] all-strategies] unique-strategies
  let sorted-counts sort-by > strategy-counts
  let order map [x -> position x sorted-counts] strategy-counts
  let sorted-strategies map [x -> item x unique-strategies] order
  report (list sorted-strategies sorted-counts)
end
@#$#@#$#@
GRAPHICS-WINDOW
9
10
446
448
-1
-1
13.0
1
10
1
1
1
0
1
1
1
-16
16
-16
16
0
0
1
ticks
30.0

BUTTON
455
11
528
44
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
536
11
599
44
NIL
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
605
11
668
44
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
942
475
1114
508
win-win-payout
win-win-payout
0
1
0.6
0.01
1
NIL
HORIZONTAL

SLIDER
941
437
1113
470
win-lose-payout
win-lose-payout
0
1
1.0
0.01
1
NIL
HORIZONTAL

SLIDER
943
556
1115
589
lose-win-payout
lose-win-payout
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
942
514
1117
547
lose-lose-payout
lose-lose-payout
0
1
0.3
0.01
1
NIL
HORIZONTAL

SLIDER
753
237
925
270
err-p-magnitude
err-p-magnitude
0
4
1.0
1
1
NIL
HORIZONTAL

PLOT
1561
334
1761
484
Turtle wealth
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "histogram [wealth] of turtles"

SLIDER
753
271
925
304
point-p-magnitude
point-p-magnitude
0
8
2.0
1
1
NIL
HORIZONTAL

SLIDER
753
307
925
340
split-p-magnitude
split-p-magnitude
0
8
2.0
1
1
NIL
HORIZONTAL

SLIDER
753
344
966
377
duplication-p-magnitude
duplication-p-magnitude
0
8
2.0
1
1
NIL
HORIZONTAL

SWITCH
474
112
686
145
assume-cooperation?
assume-cooperation?
0
1
-1000

SLIDER
480
218
652
251
population
population
10
1000
100.0
10
1
NIL
HORIZONTAL

TEXTBOX
702
113
956
162
If this is on, turtles' histories are initialized to show that they started under cooperative circumstances.
12
0.0
1

SLIDER
478
261
650
294
turnover-rate
turnover-rate
0
0.5
0.25
0.05
1
NIL
HORIZONTAL

MONITOR
2482
10
2602
55
longest memory
max [memory-length] of turtles
17
1
11

SLIDER
480
176
685
209
rounds-per-GA-event
rounds-per-GA-event
1
100
1.0
1
1
NIL
HORIZONTAL

SWITCH
839
25
1008
58
update-visuals?
update-visuals?
1
1
-1000

PLOT
1561
179
1761
329
memory length
NIL
NIL
0.0
25.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "histogram [memory-length] of turtles"

SLIDER
932
272
1104
305
point-finetune
point-finetune
1
9
2.0
1
1
NIL
HORIZONTAL

SLIDER
932
237
1104
270
error-finetune
error-finetune
1
9
1.0
1
1
NIL
HORIZONTAL

SLIDER
931
308
1103
341
split-finetune
split-finetune
1
9
1.0
1
1
NIL
HORIZONTAL

SLIDER
929
346
1109
379
duplication-finetune
duplication-finetune
1
9
1.0
1
1
NIL
HORIZONTAL

SLIDER
477
343
649
376
cost-of-memory
cost-of-memory
0
3
0.5
0.05
1
NIL
HORIZONTAL

BUTTON
673
13
829
46
repeat 500 times
repeat 500 [ go ]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
675
50
840
83
repeat 2500 times
repeat 2500 [ go ]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
756
384
949
417
wildcard-p-magnitude
wildcard-p-magnitude
0
8
1.0
1
1
NIL
HORIZONTAL

MONITOR
1560
540
1739
585
NIL
most-common-strategy 1
17
1
11

PLOT
1559
23
1759
173
long term fitness
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "histogram [average-wealth] of turtles"

TEXTBOX
756
204
906
222
orders of magnitude
12
0.0
1

TEXTBOX
936
202
1086
220
fine tuning sliders
12
0.0
1

SLIDER
932
387
1121
420
wildcard-finetune
wildcard-finetune
1
9
1.0
1
1
NIL
HORIZONTAL

TEXTBOX
756
436
906
481
Higher orders of magnitude mean lower probabilities.
12
0.0
1

MONITOR
1561
595
1756
640
2nd most common strategy
most-common-strategy 2
17
1
11

MONITOR
1347
539
1555
584
number with these strategies
count turtles with [member? strategy (most-common-strategy 1)]
17
1
11

MONITOR
1347
596
1548
641
number with these strategies
count turtles with [member? strategy (most-common-strategy 2)]
17
1
11

MONITOR
1198
386
1331
431
"cooperativeness"
mean map mean [strategy] of turtles
17
1
11

BUTTON
1176
26
1337
59
check out a turtle
ask one-of turtles [ show strategy show trimmed-history memory-length history show binary-to-decimal trimmed-history memory-length history show item binary-to-decimal trimmed-history memory-length history strategy]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
1164
68
1481
293
Check the Command Center for output\n\nThis button shows \n1. A random turtle's strategy, \n2. The part of their history they can remember, \n3. That history converted from binary to decimal form. \n4. That turtle's next move based on their strategy and history.\n\nThe strategy (1.) is indexed from 0. Their next move (4.) is the (3.)th element of their strategy. So a history of [1 0 1] would be converted to 5 and the next move would be [x x x x 1 x x x] or  [x x x x 0 x x x].
12
0.0
1

BUTTON
1173
306
1438
339
Show tally of different strategies
show strategy-count
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
333
482
533
632
Unique strategy frequency
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "histogram last strategy-count"

BUTTON
483
59
626
92
one generation
repeat rounds-per-GA-event [ go ]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
863
54
1177
119
the \"visuals\" being updated indicate the \"cooperativeness\" of a turtle's strategy (the percent of 1's) by size and memory-length by color.
12
0.0
1

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment 1" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>first strategy-count</metric>
    <metric>last strategy-count</metric>
    <enumeratedValueSet variable="rounds-per-GA-event">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cost-of-memory">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="split-finetune">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="err-p-magnitude">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wildcard-finetune">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="duplication-finetune">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="population">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="win-lose-payout">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="duplication-p-magnitude">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="point-finetune">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="point-p-magnitude">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lose-win-payout">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="error-finetune">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="split-p-magnitude">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="update-visuals?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="assume-cooperation?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wildcard-p-magnitude">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lose-lose-payout">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="turnover-rate">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="win-win-payout">
      <value value="0.6"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
