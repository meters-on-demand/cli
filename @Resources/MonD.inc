[MonD]
Measure=String
UpdateDivider=1
IfMatch=#ROOTCONFIG#
IfMatchAction=[!DisableMeasure "MonD"]
IfNotMatchAction=[!WriteKeyValue "MonD" "String" "[#ROOTCONFIG]" "#@#Mond.inc"][!WriteKeyValue "MonD" "SkinName" "[#ROOTCONFIG]" "#@#Mond.inc"][!Refresh]

SkinName=Meters on Demand
PreviewImage=
Author=Reisir
ProfilePicture=https://avatars.githubusercontent.com/u/93496808
Description=Meters on Demand, the Rainmeter package manager
String=Meters on Demand
LoadType=Skin
Load=Meters on Demand\Installer.ini

Version=v1.2.0
