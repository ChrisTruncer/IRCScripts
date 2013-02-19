#####################################################
# Channel Op Management Script
# Originally written and shared by david on #iphone
# Slightly modified for personal use by @christruncer
#####################################################

bind pub -|- !k pub:kick
bind pub -|- !kb pub:kickban
bind pub -|- !v pub:voice
bind pub -|- !dv pub:devoice
bind pub o|o !t pub:topic
bind pub -|- !o pub:op
bind pub o|o !do pub:deop
bind mode -|- "% +v" mode:voice


proc pub:kick {n uh h ch w} {
 global vkick
 if {![isvoice $n $ch] && ![matchattr $h o|o $ch] || [isop $n $ch]} {return}
 set who [lindex $w 0]
 set why [lrange $w 1 end]
 if {$why == "" || $why == " "} {set why "requested"}

 if {[info exists vkick($uh)]} {
  putserv "NOTICE $n :1 kick per minute max. please wait."
 } elseif {$who == ""} {
  putquick "KICK $ch $n :You failed to specify who to kick, so you get kicked."
 } elseif {[matchattr [nick2hand $who $ch] b]} {
  puthelp "NOTICE $n :You cannot kick channel bots, sorry."
 } elseif {[matchattr [nick2hand $who $ch] m] && ![matchattr $h n]} {
  puthelp "KICK $ch $n :You cannot kick channel masters, sorry."
 } elseif {![onchan $who $ch]} {
  puthelp "PRIVMSG $ch :No such nick. You're stupid. Be glad I don't kick you instead."
 } elseif {[matchattr $h m|m $ch]} {
  putquick "PRIVMSG $ch :Yes, Your Majesty! It shall happen immediately!"
  putquick "KICK $ch $who :$why"
 } elseif {[matchattr $h o|o $ch]} {
  putserv "PRIVMSG $ch :Happy to be of service!"
  putserv "KICK $ch $who :$n: $why"
 } elseif {[isop $who $ch] || [matchattr [nick2hand $who $ch] o|o $ch]} {
  puthelp "NOTICE $n :You cannot kick that person, sorry."
 } else {
  puthelp "PRIVMSG $ch :Yes, ma'am! Right away, ma'am!"
  puthelp "KICK $ch $who :$n: $why"
  set vkick($uh) [timer 1 [list unset vkick($uh)]]
 }
}

proc pub:kickban {n uh h ch w} {
 global vkick
 if {![isvoice $n $ch] && ![matchattr $h o|o $ch] || [isop $n $ch]} {return}
 if {[string index $w 0] == "-" && ([set bantime [expr [string range [lindex $w 0] 1 end]]] > 0) && $bantime < 120} {
  set who [lindex $w 1]
  set why [lrange $w 2 end]
 } {
  set who [lindex $w 0]
  set why [lrange $w 1 end]
  if {[matchattr $h m|m]} {set bantime 15} {set bantime 7}
 }

 if {$why == "" || $why == " "} {set why "requested"}

 if {[info exists vkick($uh)]} {
  puthelp "NOTICE $n :1 kick(ban) per minute max. please wait."
 } elseif {$who == ""} {
   putserv "NOTICE $n :You failed to specify who to kickban."
 } elseif {[matchattr [nick2hand $who $ch] b]} {
     puthelp "NOTICE $n :You cannot kick channel bots, sorry."
 } elseif {[matchattr [nick2hand $who $ch] m|m $ch] && ![matchattr $h n] || [matchattr [nick2hand $who $ch] o]} {
     puthelp "KICK $ch $n :You cannot kick channel masters, sorry."
 } elseif {![onchan $who $ch]} {
     putserv "NOTICE $n :No such nick: $who"
 } elseif {[matchattr $h m|m]} {
     putquick "PRIVMSG $ch :Yes, Your Majesty! It shall happen immediately!"
     newchanban $ch "*!*[string range [getchanhost $who] 1 end]" $h "($bantime minutes) $n: $why" $bantime
     putquick "KICK $ch $who :($bantime minute ban): $why"
 } elseif {[matchattr $h o|o]} {
     newchanban $ch "*!*[string range [getchanhost $who] 1 end]" $h "($bantime minutes) $n: $why" $bantime
 } elseif {![matchattr [nick2hand $who] o|o] && ![matchattr [nick2hand $who] v|v]} {
     newchanban $ch "*!*[string range [getchanhost $who] 1 end]" $h "(3 minutes) $n: $why" 3
     set vkick($uh) [timer 1 [list unset vkick($uh)]]
 } else {
  puthelp "NOTICE $ch :Unable to comply."
 }
}

proc pub:voice {n uh h ch w} {
 if {([matchattr $h o|o $ch] || [isvoice $n $ch] || [matchattr $h v|v $ch]) && ![isop $n $ch]} {
  set who [lindex $w 0]
  if {$who == ""} {set who $n}
  if {[onchan $who $ch] && ![isvoice $who $ch]} {
   putquick "MODE $ch +v $who"
  }
 }
}

proc pub:devoice {n uh h ch w} {
 global vdv
 if {(![matchattr $h o|o $ch] && ![isvoice $n $ch]) || [isop $n $ch]} {return} 
 if {[info exists vdv($uh)]} {
  puthelp "NOTICE $n :One de-voice per minute, max, sorry."
  return
 }
 set who [lindex $w 0]
 if {$who == ""} {set who $n}
 if {[onchan $who $ch] && [isvoice $who $ch] && ((![matchattr [nick2hand $who $ch] o|o $ch] && ![matchattr [nick2hand $who $ch] v|v $ch]) || $who == $n || [matchattr $h m|m $ch])} {
  putquick "MODE $ch -v $who"
  if {![matchattr $h o|o $ch]} {set vdv($uh) [timer 1 [list unset vdv($uh)]]}
 }
}

proc pub:topic {n uh h ch t} {
 if {[isop $n $ch]} {return}
 if {$t != "" && $t != " "} {putquick "TOPIC $ch :$t"}
}

proc pub:op {n uh h ch w} {
 set who [lindex $w 0]
 if {[isop $n $ch]} {return}
 if {$who == ""} {
  set who $n
  if {![matchattr $h o|o $ch]} {
   putquick "KICK $ch $n :You are not an op! Don't do that again!"
  } elseif {[isop $n $ch]} {
   putserv "PRIVMSG $ch :You are already opped. What are you dumb?"
  }
 }
 if {[onchan $who $ch] && ![isop $who $ch] && [matchattr $h o|o $ch] && [matchattr [nick2hand $who $ch] o|o $ch]} {putquick "MODE $ch +o $who"
 } else { puthelp "NOTICE $n :Unable to comply." }
}

proc pub:deop {n uh h ch w} {
 if {[isop $n $ch]} {return}
 set who [lindex $w 0]
 if {$who == ""} {
  set who $n
  if {![matchattr $h o|o $ch]} {
   putserv "KICK $ch $n :You are not authorized! Don't do that again!"
  } elseif {![isop $n $ch]} {
   putserv "PRIVMSG $ch :You are not opped. What are you dumb?"
  }
 }
 if {[matchattr [nick2hand $who $ch] b]} {
  puthelp "NOTICE $n :You cannot de-op channel bots, sorry."
 } elseif {[onchan $who $ch] && [isop $who $ch] && [matchattr $h o|o $ch]} {
  putquick "MODE $ch -o $who"
 } else { puthelp "NOTICE $n :Unable to comply." }
}

proc mode:voice {n uh h ch mc who} {
 global vnotice
 if {![info exists vnotice($uh)]} {
  puthelp "NOTICE $who :As a voice in this channel you have access to kick/ban people (except ops) and voice other users. Commands: !v <nick> or !k <nick> <reason> to voice or kick someone. You can also de-voice someone with !dv <nick> - To ban someone for one minute, use !kb <nick> <reason>"
  set vnotice($uh) [timer 120 [list unset vnotice($uh)]]
 }
}
