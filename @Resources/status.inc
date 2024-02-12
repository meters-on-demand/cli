[Variables]
Blur=1
Radius=3

[MeterStatus]
Meter=String
Text=Installing Meters on Demand
StringAlign=Center
X=(#SkinWidth# / 2)
ClipString=2
ClipStringW=(#SkinWidth#)
H=128
Y=(#SkinHeight# + 20)
FontSize=18
Group=Logo
AntiAlias=1
DynamicVariables=1
FontColor=[#Fill[#Installer]]
InlineSetting=Shadow  |  (#Radius#) |          0  | #Blur# | [#Outline[#Installer]]
InlineSetting2=Shadow |  (#Radius#) |  (#Radius#) | #Blur# | [#Outline[#Installer]]
InlineSetting3=Shadow |          0  |  (#Radius#) | #Blur# | [#Outline[#Installer]]
InlineSetting4=Shadow | (-#Radius#) |          0  | #Blur# | [#Outline[#Installer]]
InlineSetting5=Shadow | (-#Radius#) | (-#Radius#) | #Blur# | [#Outline[#Installer]]
InlineSetting6=Shadow |          0  | (-#Radius#) | #Blur# | [#Outline[#Installer]]
InlineSetting7=Shadow |  (#Radius#) | (-#Radius#) | #Blur# | [#Outline[#Installer]]
InlineSetting8=Shadow | (-#Radius#) |  (#Radius#) | #Blur# | [#Outline[#Installer]]
