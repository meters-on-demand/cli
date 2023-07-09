[MonD]
Measure=String
UpdateDivider=1
IfMatch=#ROOTCONFIG#
String=Meters on Demand
IfMatchAction=[!DisableMeasure "MonD"]
IfNotMatchAction=[!WriteKeyValue "MonD" "String" "[#ROOTCONFIG]" "#@#Mond.inc"][!WriteKeyValue "MonD" "SkinName" "[#ROOTCONFIG]" "#@#Mond.inc"][!Refresh]

Author=Reisir
PreviewImage=
ProfilePicture=https://avatars.githubusercontent.com/u/93496808
Description=Meters on Demand, the Rainmeter package manager

SkinName=Meters on Demand
LoadType=Skin
Load=Meters on Demand\Installer.ini
Version=v1.2.0
HeaderImage=#@#mond.bmp
Exclude=cache.json | mond.log | temp
