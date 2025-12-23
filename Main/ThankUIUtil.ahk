#Requires AutoHotkey v2.0

;打赏
AddThankUI(index) {
    MyGui := MySoftData.MyGui
    tableItem := MySoftData.TableInfo[index]
    posY := MySoftData.TabPosY + 40
    OriPosX := MySoftData.TabPosX + 15

    posX := OriPosX
    con := MyGui.Add("GroupBox", Format("x{} y{} w{} h{}", posX, posY, 850, 60), GetLang("感谢以下开发者为项目付出的智慧与汗水（排名不分先后）："))
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)
    tableItem.AllGroup.Push(con)

    posY += 30
    posX += 10
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '<a href="https://github.com/GushuLily">GushuLily</a>')
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '<a href="https://gitee.com/bogezzb">张正波</a>')
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    posX := OriPosX
    posY += 40
    con := MyGui.Add("GroupBox", Format("x{} y{} w{} h{}", posX, posY, 850, 60), GetLang("软件的开发离不开众多优秀开源项目的支持，特别感谢："))
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)
    tableItem.AllGroup.Push(con)

    posY += 30
    posX += 10
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '<a href="https://github.com/opencv/opencv">OpenCV</a>')
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '<a href="https://github.com/thqby/ahk2_lib">ahk2_lib</a>')
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '<a href="https://github.com/RapidAI/RapidOCR">RapidOCR</a>')
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '<a href="https://github.com/evilC/AHK-CvJoyInterface">AHK-CvJoyInterface</a>')
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)
    
    posX += 150
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '<a href="https://github.com/Chaoses-Ib/IbInputSimulator">IbInputSimulator</a>')
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    posX := OriPosX
    posY += 40
    con := MyGui.Add("GroupBox", Format("x{} y{} w{} h{}", posX, posY, 850, 60), GetLang("感谢以下群友在社区中的活跃参与和宝贵建议：（QQ昵称）"))
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)
    tableItem.AllGroup.Push(con)

    posY += 30
    posX += 10
    con := MyGui.Add("Text", Format("x{} y{}", posX, posY), 'AYu')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '万年置伞')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '别说*不下啦')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '仰望')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX := OriPosX
    posY += 40
    con := MyGui.Add("GroupBox", Format("x{} y{} w{} h{}", posX, posY, 850, 420), GetLang("特别鸣谢以下用户的慷慨打赏（按时间顺序）：（打赏用户名）"))
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)
    tableItem.AllGroup.Push(con)

    posX := OriPosX
    posY += 30
    posX += 10
    con := MyGui.Add("Text", Format("x{} y{}", posX, posY), '*物')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '*援')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '0*1')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '*印')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), 'R*x')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '**')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), 'M*Z')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '*湖')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX := OriPosX
    posY += 30
    posX += 10
    con := MyGui.Add("Text", Format("x{} y{}", posX, posY), 'w*u')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '*子_2')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '*翌')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), 'O*o')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '*凌')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '**奇')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), 'D*g')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '*樱桃')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX := OriPosX
    posY += 30
    posX += 10
    con := MyGui.Add("Text", Format("x{} y{}", posX, posY), '*子')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '*Y')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '*阳')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '*')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), 'M*n')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '*灬')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '*云')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '*静')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX := OriPosX
    posY += 30
    posX += 10
    con := MyGui.Add("Text", Format("x{} y{}", posX, posY), '*铁')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '*丁')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '*物')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '*财')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '**杰')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '*尘')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '*月')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '**明')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX := OriPosX
    posY += 30
    posX += 10
    con := MyGui.Add("Text", Format("x{} y{}", posX, posY), 'V*.')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '*.')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '*伟')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '*觉')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '*愿')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '*伟')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '*戴')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), 'P*a')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX := OriPosX
    posY += 30
    posX += 10
    con := MyGui.Add("Text", Format("x{} y{}", posX, posY), 'H*a')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '*伟')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), 'H*G')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '*冬')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '*黑')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '*怪')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '*豆')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '*浪')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX := OriPosX
    posY += 30
    posX += 10
    con := MyGui.Add("Text", Format("x{} y{}", posX, posY), '*伟')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '*禹')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '**超')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), 'd*p')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '**俊')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '超*7')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '**金')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '*线')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX := OriPosX
    posY += 30
    posX += 10
    con := MyGui.Add("Text", Format("x{} y{}", posX, posY), '*哈')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), 'T*n')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '*宝')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '银联云闪')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '*正')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '*丢')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '*菰')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '*')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX := OriPosX
    posY += 30
    posX += 10
    con := MyGui.Add("Text", Format("x{} y{}", posX, posY), 'S*h')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '*橙子')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), 'Q*7')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), 'C*e')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '*跃')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), 's*1')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '7*4')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '*A')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX := OriPosX
    posY += 30
    posX += 10
    con := MyGui.Add("Text", Format("x{} y{}", posX, posY), '*楠')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '*广')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '*啊')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '认*n')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '*天')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '*)')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '*源')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '*悬')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX := OriPosX
    posY += 30
    posX += 10
    con := MyGui.Add("Text", Format("x{} y{}", posX, posY), '*卦')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '*上')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '*人')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '重*e')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '*刘')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '*楹')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '*川')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '*维')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX := OriPosX
    posY += 30
    posX += 10
    con := MyGui.Add("Text", Format("x{} y{}", posX, posY), '*欣')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '*美')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '*旭')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '*样')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '*酒')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '*室')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '*冘')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '*1')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX := OriPosX
    posY += 30
    posX += 10
    con := MyGui.Add("Text", Format("x{} y{}", posX, posY), '*一')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '*正')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX := OriPosX
    posY += 50
    con := MyGui.Add("GroupBox", Format("x{} y{} w{} h{}", posX, posY, 850, 400), GetLang("感谢以下用户积极参与测试、反馈Bug并提出优化建议：（QQ昵称）"))
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))
    tableItem.AllGroup.Push(con)

    posX := OriPosX
    posY += 30
    posX += 10
    con := MyGui.Add("Text", Format("x{} y{}", posX, posY), '嘟嘟骑士')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '无名指迷了路')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), 'anchorage')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '踩着丶浪花上')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '跑路王')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '≡ω≡')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), 'R')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), 'Eason')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX := OriPosX
    posX += 10
    posY += 30
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '118*535')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '黑猫')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '小神PLUS')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '淡水鱼')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), 'singaplus')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '锕羽')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '不完*个id')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), 'cool')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX := OriPosX
    posX += 10
    posY += 30
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '鸡冠掉了')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), 'Zoe')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '空白')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '沐火火')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '万年置伞')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '浪淘沙水无痕')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), 'aa')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '。。')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX := OriPosX
    posX += 10
    posY += 30
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '陈小金666')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '仰望')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '新世纪')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), 'lipeep')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '丑僧')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), 'Kiss*end')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '从黑夜到白昼')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), 'dr')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX := OriPosX
    posX += 10
    posY += 30
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '纵马*向自由')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '132*569')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '463*752')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '719*168')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '555931')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), 'Ray')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '若水')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), ';snad')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX := OriPosX
    posX += 10
    posY += 30
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '欣哥哥')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '自己9')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '白悠悠')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), 'Aluo')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), 'light up')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '拾柒')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '/…/…')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '米娅')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX := OriPosX
    posX += 10
    posY += 30
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '魂吞玛瑙')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '衘风')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '十柒')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '三二一')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '陈碎碎')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), 'lubey')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '10×10')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '~~')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX := OriPosX
    posX += 10
    posY += 30
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), 'hsuyoung')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '年年有鱼')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '小帅哥')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), 'Lqoid')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), 'ฒ☭ .')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), 'wakaka')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '循此苦旅')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '梅长苏')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX := OriPosX
    posX += 10
    posY += 30
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '香蕉')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), 'KAIRO')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), 'Wings')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '惦念')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '曦曦')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '蒋小枫')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '九歌白玉')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), 'TO_OT')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX := OriPosX
    posX += 10
    posY += 30
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '白之契约')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '高悬')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '总要有点判头...')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '扬帆起航')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '132*569')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '烟云')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), 'dr')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '刘')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX := OriPosX
    posX += 10
    posY += 30
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '星汉*路吾修')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '涅槃')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), 'Logan')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '空白')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '瓜瓜')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '低调如我')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '奥运特别号')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '漂流木')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX := OriPosX
    posX += 10
    posY += 30
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '免')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '一心向学')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), 'wyy')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '薛定谔的真猫')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '琰玥')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), 'abc')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX += 100
    con := MyGui.Add("Link", Format("x{} y{}", posX, posY), '侠客')
    tableItem.AllConArr.Push(ItemConInfo(con, tableItem, 1))

    posX := OriPosX
    posY += 50
    con := MyGui.Add("Text", Format("x{} y{} w{} h{}", posX, posY, 850, 70), 
    Format("{}`n{}", GetLang("感谢每一位陪伴我们走过这段旅程的粉丝和群友们！是你们的支持与信任，让这个软件从一个小小的想法，一步步成长为今天的样子。每一次的鼓励、每一条的建议，都是我们前进的动力。"), GetLang("感谢你们不离不弃，与我们共同见证每一次的迭代与成长。")))
    con.SetFont((Format("S{} W{} Q{}", 12, 600, 0)))
    con.Focus()
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    posX := OriPosX
    posY += 75
    con := MyGui.Add("Text", Format("x{} y{} w{} h{}", posX, posY, 850, 70),
    Format("{}`n{}", GetLang("再次感谢所有关心、支持、帮助过这个项目的每一个人！"), GetLang("因为有你，这个项目才变得更有意义。")))
    con.SetFont((Format("S{} W{} Q{}", 12, 600, 0)))
    con.Focus()
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

     posX := OriPosX
    posY += 50
    con := MyGui.Add("Text", Format("x{} y{} w{} h30", posX + 600, posY, 200), Format("—— 若梦兔{}", GetLang("敬上")))
    con.SetFont((Format("S{} W{} Q{}", 12, 600, 0)))
    con.Focus()
    conInfo := ItemConInfo(con, tableItem, 1)
    tableItem.AllConArr.Push(conInfo)

    posY += 50
    MySoftData.TableInfo[index].underPosY := posY
}