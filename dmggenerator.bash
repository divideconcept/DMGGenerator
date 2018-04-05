#!/bin/bash
#(c) 2018 Robin Lobel
#usage: dmggenerator.bash dmgpath apppath backgroundpath [licensepath] [language1] [language2] [...]

if [ -z "$3" ]
then
    echo "Missing arguments"
    exit
fi

rezfolder=$(dirname "$0")

dmgpath=$1
dmgfolder=$(dirname "$dmgpath")
dmgfile=$(basename "$dmgpath")
dmgname=${dmgfile%.*}

apppath=$2
appfolder=$(dirname "$apppath")
appfile=$(basename "$apppath")
appname=${appfile%.*}

backgroundpath=$3
backgroundfile=$(basename "$backgroundpath")

temppath=/tmp/dmggenerator

echo "DMG Generator 1.0"

echo "Initializing the DMG..."

rm -r $temppath 2>/dev/null
mkdir -p $temppath

#create Applications shortcut, copy background file, create DS_Store
ln -s /Applications $temppath/Applications
mkdir -p $temppath/.hidden
cp "$backgroundpath" $temppath/.hidden/"$backgroundfile"
touch $temppath/.DS_Store

mkdir -p "$dmgfolder"

mv "$apppath" $temppath
hdiutil create "$dmgpath" -srcfolder $temppath -ov -volname "$dmgname" -format UDRW
mv $temppath/"$appfile" "$appfolder"

echo "Setting the layout..."

diskutil eject /Volumes/"$dmgname" 2>/dev/null
hdiutil mount "$dmgpath"

#find dimensions
backgroundwidth=$(sips -g pixelWidth "$backgroundpath" | tail -n1 | cut -d" " -f4)
backgroundheight=$(sips -g pixelHeight "$backgroundpath" | tail -n1 | cut -d" " -f4)
echo "background size: $backgroundwidth x $backgroundheight"

topleftx=100
toplefty=100
let bottomrightx=$backgroundwidth+$topleftx
let bottomrighty=$backgroundheight+$toplefty
let centery=$backgroundheight/2
let centerxmyapp=$backgroundwidth/4
let centerxapps=3*$backgroundwidth/4

#set the layout
echo '
tell application "Finder"
    tell disk "'$dmgname'"
       set current view of container window to icon view
       set theViewOptions to the icon view options of container window
       set icon size of theViewOptions to 96
       set background picture of theViewOptions to file ".hidden:'$backgroundfile'"
       open
       set toolbar visible of container window to false
       set statusbar visible of container window to false
       set the bounds of container window to {'$topleftx', '$toplefty', '$bottomrightx', '$bottomrighty'}
       set position of item "'$appfile'" of container window to {'$centerxmyapp', '$centery'}
       set position of item "Applications" of container window to {'$centerxapps', '$centery'}
       update without registering applications
       delay 1
       close
       eject
    end tell
end tell
' | osascript


diskutil eject /Volumes/"$dmgname" 2>/dev/null
hdiutil mount "$dmgfile"

bless --folder /Volumes/"$dmgname" --openfolder /Volumes/"$dmgname"
diskutil eject /Volumes/"$dmgname"

if [ ! -z "$4" ]
then
    echo "Adding the licenses..."

    licensepath=$4
    licensefolder=$(dirname "$licensepath")
    licensefile=$(basename "$licensepath")
    licensename=${licensefile%.*}
    licenseextension=${licensefile##*.}

    declare -a languagename
    languagename[0]="en"
    languagename[1]="fr"
    languagename[2]="de"
    languagename[3]="it"
    languagename[4]="sp"
    languagename[5]="ja"
    languagename[6]="ru"
    languagename[7]="ko"
    languagename[8]="zh"
    languagename[9]="pt"

    defaultlanguageid=0
    if [ ! -z "$5" ]
    then
        for l in "${!languagename[@]}"; do
            if [ "${languagename[$l]}" == "$5" ]
            then defaultlanguageid=$l
            fi
        done
    fi

    #add language index
    echo -e "data 'LPic' (5000) {" > $temppath/license.r
    echo -e "\t$\"000$defaultlanguageid\"" >> $temppath/license.r #default language
    echo -e "\t$\"000A\"" >> $temppath/license.r #number of languages
    #Region codes from CarbonCore.framework/Versions/A/Headers/Script.h, ID in file (offset from 5000), is 2-byte language
    echo -e "\t$\"0000 0000 0000\"" >> $temppath/license.r #English
    echo -e "\t$\"0001 0001 0000\"" >> $temppath/license.r #French
    echo -e "\t$\"0003 0002 0000\"" >> $temppath/license.r #German
    echo -e "\t$\"0004 0003 0000\"" >> $temppath/license.r #Italian
    echo -e "\t$\"0008 0004 0000\"" >> $temppath/license.r #Spanish
    echo -e "\t$\"000E 0005 0001\"" >> $temppath/license.r #Japanese
    echo -e "\t$\"0031 0006 0001\"" >> $temppath/license.r #Russian
    echo -e "\t$\"0033 0007 0001\"" >> $temppath/license.r #Korean
    echo -e "\t$\"0034 0008 0001\"" >> $temppath/license.r #Chinese
    echo -e "\t$\"0047 0009 0000\"" >> $temppath/license.r #Portuguese
    echo -e "};\r\n" >> $temppath/license.r

cat >> $temppath/license.r <<- EOM
data 'styl' (5000, "English") {
        $"0000"                                               /* .. */
};

data 'styl' (5001, "French") {
        $"0000"                                               /* .. */
};

data 'styl' (5002, "German") {
        $"0000"                                               /* .. */
};

data 'styl' (5003, "Italian") {
        $"0000"                                               /* .. */
};

data 'styl' (5004, "Spanish") {
        $"0000"                                               /* .. */
};

data 'styl' (5005, "Japanese") {
        $"0000"                                               /* .. */
};

data 'styl' (5006, "Russian") {
        $"0000"                                               /* .. */
};

data 'styl' (5007, "Korean") {
        $"0000"                                               /* .. */
};

data 'styl' (5008, "Chinese (China)") {
        $"0000"                                               /* .. */
};

data 'styl' (5009, "Portuguese (Brazil)") {
        $"0000"                                               /* .. */
};

data 'STR#' (5000, "English") {
        $"0006 0745 6E67 6C69 7368 0541 6772 6565"            /* ...English.Agree */
        $"0844 6973 6167 7265 6505 5072 696E 7407"            /* .Disagree.Print. */
        $"5361 7665 2E2E 2E7A 4966 2079 6F75 2061"            /* Save...zIf you a */
        $"6772 6565 2077 6974 6820 7468 6520 7465"            /* gree with the te */
        $"726D 7320 6F66 2074 6869 7320 6C69 6365"            /* rms of this lice */
        $"6E73 652C 2070 7265 7373 20D2 4167 7265"            /* nse, press _Agre */
        $"65D3 2074 6F20 696E 7374 616C 6C20 7468"            /* e_ to install th */
        $"6520 736F 6674 7761 7265 2E20 4966 2079"            /* e software. If y */
        $"6F75 2064 6F20 6E6F 7420 6167 7265 652C"            /* ou do not agree, */
        $"2070 7265 7373 20D2 4469 7361 6772 6565"            /*  press _Disagree */
        $"D32E"                                               /* _. */
};

data 'STR#' (5001, "French") {
        $"0006 0846 7261 6E8D 6169 7308 4163 6365"            /* ...Fran_ais.Acce */
        $"7074 6572 0752 6566 7573 6572 0849 6D70"            /* pter.Refuser.Imp */
        $"7269 6D65 720E 456E 7265 6769 7374 7265"            /* rimer.Enregistre */
        $"722E 2E2E BA53 6920 766F 7573 2061 6363"            /* r..._Si vous acc */
        $"6570 7465 7A20 6C65 7320 7465 726D 6573"            /* eptez les termes */
        $"2064 6520 6C61 2070 728E 7365 6E74 6520"            /*  de la pr_sente  */
        $"6C69 6365 6E63 652C 2063 6C69 7175 657A"            /* licence, cliquez */
        $"2073 7572 2022 4163 6365 7074 6572 2220"            /*  sur "Accepter"  */
        $"6166 696E 2064 2769 6E73 7461 6C6C 6572"            /* afin d'installer */
        $"206C 6520 6C6F 6769 6369 656C 2E20 5369"            /*  le logiciel. Si */
        $"2076 6F75 7320 6E27 9074 6573 2070 6173"            /*  vous n'_tes pas */
        $"2064 2761 6363 6F72 6420 6176 6563 206C"            /*  d'accord avec l */
        $"6573 2074 6572 6D65 7320 6465 206C 6120"            /* es termes de la  */
        $"6C69 6365 6E63 652C 2063 6C69 7175 657A"            /* licence, cliquez */
        $"2073 7572 2022 5265 6675 7365 7222 2E"              /*  sur "Refuser". */
};

data 'STR#' (5002, "German") {
        $"0006 0744 6575 7473 6368 0B41 6B7A 6570"            /* ...Deutsch.Akzep */
        $"7469 6572 656E 0841 626C 6568 6E65 6E07"            /* tieren.Ablehnen. */
        $"4472 7563 6B65 6E0A 5369 6368 6572 6E2E"            /* Drucken_Sichern. */
        $"2E2E E74B 6C69 636B 656E 2053 6965 2069"            /* .._Klicken Sie i */
        $"6E20 D241 6B7A 6570 7469 6572 656E D32C"            /* n _Akzeptieren_, */
        $"2077 656E 6E20 5369 6520 6D69 7420 6465"            /*  wenn Sie mit de */
        $"6E20 4265 7374 696D 6D75 6E67 656E 2064"            /* n Bestimmungen d */
        $"6573 2053 6F66 7477 6172 652D 4C69 7A65"            /* es Software-Lize */
        $"6E7A 7665 7274 7261 6773 2065 696E 7665"            /* nzvertrags einve */
        $"7273 7461 6E64 656E 2073 696E 642E 2046"            /* rstanden sind. F */
        $"616C 6C73 206E 6963 6874 2C20 6269 7474"            /* alls nicht, bitt */
        $"6520 D241 626C 6568 6E65 6ED3 2061 6E6B"            /* e _Ablehnen_ ank */
        $"6C69 636B 656E 2E20 5369 6520 6B9A 6E6E"            /* licken. Sie k_nn */
        $"656E 2064 6965 2053 6F66 7477 6172 6520"            /* en die Software  */
        $"6E75 7220 696E 7374 616C 6C69 6572 656E"            /* nur installieren */
        $"2C20 7765 6E6E 2053 6965 20D2 416B 7A65"            /* , wenn Sie _Akze */
        $"7074 6965 7265 6ED3 2061 6E67 656B 6C69"            /* ptieren_ angekli */
        $"636B 7420 6861 6265 6E2E"                           /* ckt haben. */
};

data 'STR#' (5003, "Italian") {
        $"0006 0849 7461 6C69 616E 6F07 4163 6365"            /* ...Italiano.Acce */
        $"7474 6F07 5269 6669 7574 6F06 5374 616D"            /* tto.Rifiuto.Stam */
        $"7061 0B52 6567 6973 7472 612E 2E2E 7F53"            /* pa.Registra....S */
        $"6520 6163 6365 7474 6920 6C65 2063 6F6E"            /* e accetti le con */
        $"6469 7A69 6F6E 6920 6469 2071 7565 7374"            /* dizioni di quest */
        $"6120 6C69 6365 6E7A 612C 2066 6169 2063"            /* a licenza, fai c */
        $"6C69 6320 7375 2022 4163 6365 7474 6F22"            /* lic su "Accetto" */
        $"2070 6572 2069 6E73 7461 6C6C 6172 6520"            /*  per installare  */
        $"696C 2073 6F66 7477 6172 652E 2041 6C74"            /* il software. Alt */
        $"7269 6D65 6E74 6920 6661 6920 636C 6963"            /* rimenti fai clic */
        $"2073 7520 2252 6966 6975 746F 222E"                 /*  su "Rifiuto". */
};

data 'STR#' (5004, "Spanish") {
        $"0006 0745 7370 6196 6F6C 0741 6365 7074"            /* ...Espa_ol.Acept */
        $"6172 0A4E 6F20 6163 6570 7461 7208 496D"            /* ar_No aceptar.Im */
        $"7072 696D 6972 0A47 7561 7264 6172 2E2E"            /* primir_Guardar.. */
        $"2EC0 5369 2065 7374 8720 6465 2061 6375"            /* ._Si est_ de acu */
        $"6572 646F 2063 6F6E 206C 6F73 2074 8E72"            /* erdo con los t_r */
        $"6D69 6E6F 7320 6465 2065 7374 6120 6C69"            /* minos de esta li */
        $"6365 6E63 6961 2C20 7075 6C73 6520 2241"            /* cencia, pulse "A */
        $"6365 7074 6172 2220 7061 7261 2069 6E73"            /* ceptar" para ins */
        $"7461 6C61 7220 656C 2073 6F66 7477 6172"            /* talar el softwar */
        $"652E 2045 6E20 656C 2073 7570 7565 7374"            /* e. En el supuest */
        $"6F20 6465 2071 7565 206E 6F20 6573 748E"            /* o de que no est_ */
        $"2064 6520 6163 7565 7264 6F20 636F 6E20"            /*  de acuerdo con  */
        $"6C6F 7320 748E 726D 696E 6F73 2064 6520"            /* los t_rminos de  */
        $"6573 7461 206C 6963 656E 6369 612C 2070"            /* esta licencia, p */
        $"756C 7365 2022 4E6F 2061 6365 7074 6172"            /* ulse "No aceptar */
        $"2E22"                                               /* ." */
};

data 'STR#' (5005, "Japanese") {
        $"0006 084A 6170 616E 6573 650A 93AF 88D3"            /* ...Japanese____ */
        $"82B5 82DC 82B7 0C93 AF88 D382 B582 DC82"            /* _____._______ */
        $"B982 F108 88F3 8DFC 82B7 82E9 0795 DB91"            /* ___.________.__ */
        $"B62E 2E2E B496 7B83 5C83 7483 6783 4583"            /* _...__{_\_t_g_E_ */
        $"4783 418E 6797 708B 9691 F88C 5F96 F182"            /* G_A_g_p_________ */
        $"CC8F F08C 8F82 C993 AF88 D382 B382 EA82"            /* _____b_______ */
        $"E98F EA8D 8782 C982 CD81 4183 5C83 7483"            /* ______A_\_t_ */
        $"6783 4583 4783 4182 F083 4383 9383 5883"            /* g_E_G_A___C___X_ */
        $"6781 5B83 8B82 B782 E982 BD82 DF82 C981"            /* g_[_________ */
        $"7593 AF88 D382 B582 DC82 B781 7682 F089"            /* u_________v___ */
        $"9F82 B582 C482 AD82 BE82 B382 A281 4281"            /* ____A________B_ */
        $"4093 AF88 D382 B382 EA82 C882 A28F EA8D"            /* @________A____ */
        $"8782 C982 CD81 4181 7593 AF88 D382 B582"            /* ____A_u______ */
        $"DC82 B982 F181 7682 F089 9F82 B582 C482"            /* _____v_______A */
        $"AD82 BE82 B382 A281 42"                             /* ________B */
};

data 'STR#' (5006, "Russian (Russia)") {
        $"0006 0752 7573 7369 616E 0891 EEE3 EBE0"            /* ...Russian._____ */
        $"F1E5 ED0B 8DE5 20F1 EEE3 EBE0 F1E5 ED0B"            /* ___.__ ________. */
        $"90E0 F1EF E5F7 E0F2 E0F2 FC0A 91EE F5F0"            /* _______________ */
        $"E0ED E8F2 FCC9 9585 F1EB E820 E2FB 20F1"            /* _____c____ __ _ */
        $"EEE3 EBE0 F1ED FB20 F120 F3F1 EBEE E2E8"            /* _______ _ ______ */
        $"DFEC E820 FDF2 EEE9 20EB E8F6 E5ED E7E8"            /* ___ ____ _______ */
        $"E82C 20ED E0E6 ECE8 F2E5 20C7 91EE E3EB"            /* _, _______ O___ */
        $"E0F1 E5ED C82C 20F7 F2EE E1FB 20F3 F1F2"            /* _____, _____ ___ */
        $"E0ED EEE2 E8F2 FC20 EFF0 EEE3 F0E0 ECEC"            /* _______ ________ */
        $"EDEE E520 EEE1 E5F1 EFE5 F7E5 EDE8 E52E"            /* ___ ___________. */
        $"2085 F1EB E820 E2FB 20ED E520 F1EE E3EB"            /*  ____ __ __ ____ */
        $"E0F1 EDFB 2C20 EDE0 E6EC E8F2 E520 C78D"            /* ____, _______ A */
        $"E520 F1EE E3EB E0F1 E5ED C82E"                      /* _ _________. */
};

data 'STR#' (5007, "Korean") {
        $"0006 064B 6F72 6561 6E04 B5BF C0C7 09B5"            /* ...Korean.____Z */
        $"BFC0 C720 BEC8 C7D4 06C7 C1B8 B0C6 AE07"            /* ___ ____.____T. */
        $"C0FA C0E5 2E2E 2E7F 7EBB E7BF EB20 B0E8"            /* ____....~____ __ */
        $"BEE0 BCAD C0C7 20B3 BBBF EBBF A120 B5BF"            /* ____ ____ __ */
        $"C0C7 C7CF B8E9 2C20 22B5 BFC0 C722 20B4"            /* _____, "____" _ */
        $"DCC3 DFB8 A620 B4AD B7AF 20BC D2C7 C1C6"            /* ____ ____ _____ */
        $"AEBF FEBE EEB8 A620 BCB3 C4A1 C7CF BDCA"            /* _____ __g___ */
        $"BDC3 BFC0 2E20 B5BF C0C7 C7CF C1F6 20BE"            /* _y_. ________ _ */
        $"CAB4 C2B4 D9B8 E92C 2022 B5BF C0C7 20BE"            /* ____, "____ _ */
        $"C8C7 D422 20B4 DCC3 DFB8 A620 B4A9 B8A3"            /* ___" _____ ____ */
        $"BDCA BDC3 BFC0 2E"                                  /* __y_. */
};

data 'STR#' (5008, "Chinese (China)") {
        $"0006 1253 696D 706C 6966 6965 6420 4368"            /* ...Simplified Ch */
        $"696E 6573 6504 CDAC D2E2 06B2 BBCD ACD2"            /* inese.___.____ */
        $"E204 B4F2 D3A1 06B4 E6B4 A2A1 AD54 C8E7"            /* _.___.____T__ */
        $"B9FB C4FA CDAC D2E2 B1BE D0ED BFC9 D0AD"            /* ____________ */
        $"D2E9 B5C4 CCF5 BFEE A3AC C7EB B0B4 A1B0"            /* ____________ */
        $"CDAC D2E2 A1B1 C0B4 B0B2 D7B0 B4CB C8ED"            /* ____________ */
        $"BCFE A1A3 C8E7 B9FB C4FA B2BB CDAC D2E2"            /* _______________ */
        $"A3AC C7EB B0B4 A1B0 B2BB CDAC D2E2 A1B1"            /* ___________ */
        $"A1A3"                                               /* __ */
};

data 'STR#' (5009, "Portuguese (Brazil)") {
        $"0006 1150 6F72 7475 6775 9073 2C20 4272"            /* ...Portugu_s, Br */
        $"6173 696C 0943 6F6E 636F 7264 6172 0944"            /* asil_Concordar_D */
        $"6973 636F 7264 6172 0849 6D70 7269 6D69"            /* iscordar.Imprimi */
        $"7209 5361 6C76 6172 2E2E 2E8C 5365 2065"            /* r_Salvar..._Se e */
        $"7374 8720 6465 2061 636F 7264 6F20 636F"            /* st_ de acordo co */
        $"6D20 6F73 2074 6572 6D6F 7320 6465 7374"            /* m os termos dest */
        $"6120 6C69 6365 6E8D 612C 2070 7265 7373"            /* a licen_a, press */
        $"696F 6E65 2022 436F 6E63 6F72 6461 7222"            /* ione "Concordar" */
        $"2070 6172 6120 696E 7374 616C 6172 206F"            /*  para instalar o */
        $"2073 6F66 7477 6172 652E 2053 6520 6E8B"            /*  software. Se n_ */
        $"6F20 6573 7487 2064 6520 6163 6F72 646F"            /* o est_ de acordo */
        $"2C20 7072 6573 7369 6F6E 6520 2244 6973"            /* , pressione "Dis */
        $"636F 7264 6172 222E"                                /* cordar". */
};

EOM

    if [ -z "$5" ]
    then
        echo "  adding en license..."
        if [ $licenseextension == "rtf" ]
        then echo -e "data 'RTF ' (5000, \"en\") {" >> $temppath/license.r
        else echo -e "data 'TEXT' (5000, \"en\") {" >> $temppath/license.r
        fi
        hexdump -v -e '"\t" "$|" 16/1 "%02x" "|\n"' "$licensepath" | sed 's/|/\"/g' >> $temppath/license.r
        echo -e "};\r\n" >> $temppath/license.r
    else
        while :
        do
            language=$5
            if [ -z $language ]
            then
                break
            fi
            shift

            for l in "${!languagename[@]}"; do
                if [ "${languagename[$l]}" == "$language" ]
                then
                    echo "  adding ${languagename[$l]} license..."
                    if [ $licenseextension == "rtf" ]
                    then echo -e "data 'RTF ' (500$l, \"${languagename[$l]}\") {" >> $temppath/license.r
                    else echo -e "data 'TEXT' (500$l, \"${languagename[$l]}\") {" >> $temppath/license.r
                    fi
                    hexdump -v -e '"\t" "$|" 16/1 "%02x" "|\n"' "$licensefolder/$licensename${languagename[$l]}.$licenseextension" | sed 's/|/\"/g' >> $temppath/license.r
                    echo -e "};\r\n" >> $temppath/license.r
                fi
            done
        done
    fi

    #add the license and make the image read only
    hdiutil convert "$dmgpath" -format UDRO -ov -o "$dmgpath"
    hdiutil unflatten "$dmgpath"
    "$rezfolder"/Rez $temppath/license.r -o $temppath/license.rsrc
    "$rezfolder"/ResMerger -a $temppath/license.rsrc -o "$dmgpath"
    hdiutil flatten "$dmgpath"

fi

echo "Finalizing..."
hdiutil convert "$dmgpath" -format UDZO -ov -o "$dmgpath"

rm -r $temppath
echo ""
