#Requires AutoHotkey v2.0

;打赏
AddThankUI(index) {
    MyGui := MySoftData.MyGui
    posY := MySoftData.TabPosY + 40
    OriPosX := MySoftData.TabPosX + 15

    posX := OriPosX
    con := MyGui.Add("Text", Format("x{} y{} w{} h{}", posX, posY, 850, 70),
    "感谢每一位陪伴我们走过这段旅程的粉丝和群友们！是你们的支持与信任，让这个软件从一个小小的想法，一步步成长为今天的样子。每一次的鼓励、每一条的建议，都是我们前进的动力。`n感谢你们不离不弃，与我们共同见证每一次的迭代与成长。")
    con.SetFont((Format("S{} W{} Q{}", 12, 600, 0)))
    con.Focus()

    posX := OriPosX
    posY += 75
    MyGui.Add("GroupBox", Format("x{} y{} w{} h{}", posX, posY, 850, 60), "感谢以下开发者为项目付出的智慧与汗水（排名不分先后）：")

    posY += 30
    posX += 10
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '<a href="https://github.com/GushuLily">GushuLily</a>')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '<a href="https://gitee.com/bogezzb">张正波</a>')

    posX := OriPosX
    posY += 35
    MyGui.Add("GroupBox", Format("x{} y{} w{} h{}", posX, posY, 850, 60), "软件的开发离不开众多优秀开源项目的支持，特别感谢：")

    posY += 30
    posX += 10
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '<a href="https://github.com/opencv/opencv">OpenCV</a>')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '<a href="https://github.com/thqby/ahk2_lib">ahk2_lib</a>')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '<a href="https://github.com/RapidAI/RapidOCR">RapidOCR</a>')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '<a href="https://github.com/evilC/AHK-CvJoyInterface">AHK-CvJoyInterface</a>')

    posX := OriPosX
    posY += 35
    MyGui.Add("GroupBox", Format("x{} y{} w{} h{}", posX, posY, 850, 60), "感谢以下群友在社区中的活跃参与和宝贵建议：（QQ昵称）")

    posY += 30
    posX += 10
    MyGui.Add("Text", Format("x{} y{}", posX, posY), 'AYu')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '万年置伞')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '别说*不下啦')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '一根香蕉')

    posX := OriPosX
    posY += 35
    MyGui.Add("GroupBox", Format("x{} y{} w{} h{}", posX, posY, 850, 500), "感谢以下用户积极参与测试、反馈Bug并提出优化建议：（QQ昵称）")

    posY += 30
    posX += 10
    MyGui.Add("Text", Format("x{} y{}", posX, posY), '嘟嘟骑士')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '无名指迷了路')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), 'anchorage')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '踩着丶浪花上')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '跑路王')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '≡ω≡')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), 'R')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), 'Eason')

    posX := OriPosX
    posX += 10
    posY += 30
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '118*535')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '黑猫')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '小神PLUS')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '淡水鱼')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), 'singaplus')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '锕羽')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '不完*个id')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), 'cool')

    posX := OriPosX
    posX += 10
    posY += 30
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '鸡冠掉了')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), 'Zoe')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '空白')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '沐火火')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '万年置伞')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '浪淘沙水无痕')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), 'aa')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '。。')

    posX := OriPosX
    posX += 10
    posY += 30
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '陈小金666')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '仰望')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '新世纪')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), 'lipeep')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '丑僧')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), 'Kiss*end')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '从黑夜到白昼')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), 'dr')

    posX := OriPosX
    posX += 10
    posY += 30
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '纵马*向自由')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '132*569')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '463*752')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '719*168')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '555931')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), 'Ray')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '若水')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), ';snad')

    posX := OriPosX
    posX += 10
    posY += 30
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '欣哥哥')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '自己9')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '白悠悠')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), 'Aluo')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), 'light up')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '拾柒')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '/…/…')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '米娅')

    posX := OriPosX
    posX += 10
    posY += 30
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '魂吞玛瑙')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '衘风')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '十柒')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '三二一')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '陈碎碎')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), 'lubey')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '10×10')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '~~')

    posX := OriPosX
    posX += 10
    posY += 30
    MyGui.Add("Link", Format("x{} y{}", posX, posY), 'hsuyoung')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '年年有鱼')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '小帅哥')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), 'Lqoid')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), 'ฒ☭ .')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), 'wakaka')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '循此苦旅')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '梅长苏')

    posX := OriPosX
    posX += 10
    posY += 30
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '香蕉')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), 'KAIRO')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), 'Wings')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '惦念')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '曦曦')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '蒋小枫')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '九歌白玉')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), 'TO_OT')

    posX := OriPosX
    posX += 10
    posY += 30
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '白之契约')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '高悬')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '总要有点判头...')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '扬帆起航')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '132*569')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '烟云')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), 'dr')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '刘')

    posX := OriPosX
    posX += 10
    posY += 30
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '星汉*路吾修')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '涅槃')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), 'Logan')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '空白')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '瓜瓜')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '低调如我')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '奥运特别号')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '漂流木')

    posX := OriPosX
    posX += 10
    posY += 30
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '免')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '一心向学')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), 'wyy')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '薛定谔的真猫')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '琰玥')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), 'abc')

    posX += 100
    MyGui.Add("Link", Format("x{} y{}", posX, posY), '侠客')

    posY += 35
    MySoftData.TableInfo[index].underPosY := posY
}