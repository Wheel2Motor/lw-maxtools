rollout rltNavigator "快速视角导航" width:300(

    local front = FALSE
    
    button btnFov1 "FOV : 1" pos:[10, 10] width:80 height:40
    button btnFov35 "FOV : 35" pos:[10, 60] width:80 height:40
    button btnFov45 "FOV : 45" pos:[10, 110] width:80 height:20
    spinner spnFov "" range:[1, 120, viewport.getfov()] scale:1 type:#FLOAT pos:[10, 140] width:80 height:20
    button btnClipping "远近截面" pos:[10, 165] width:80 height:20
    checkbox ckbAlign "自动聚焦" tooltip:"自动聚焦到当前选择物体" pos:[10, 195] width:80 height:20 checked:TRUE
    button btnLeft "左" pos:[120, 80] width:50 height:50
    button btnRight "右" pos:[220, 80] width:50 height:50
    button btnCenter "后" pos:[170, 80] width:50 height:50
    button btnUp "上" pos:[170, 30] width:50 height:50
    button btnDown "下" pos:[170, 130] width:50 height:50
    
    on btnFov1 pressed do (
        max vpt persp user
        viewport.setFov(1)
        spnFov.value = 1
        if ckbAlign.checked do max zoomext sel
        setNeedsRedraw()
        )
    	
    on btnFov35 pressed do (
        max vpt persp user
        viewport.setFov(35)
        spnFov.value = 35
        if ckbAlign.checked do max zoomext sel
        setNeedsRedraw()
        )
    	
    on btnFov45 pressed do (
        max vpt persp user
        viewport.setFov(45)
        spnFov.value = 45
        if ckbAlign.checked do max zoomext sel
        setNeedsRedraw()
        )
    	
    on spnFov changed val do (
        max vpt persp user
        viewport.setFov(spnFov.value)
        if ckbAlign.checked do max zoomext sel
        setNeedsRedraw()
        )
    	
    on btnCenter pressed do (
        if front == TRUE THEN (
            max vpt front
            front = FALSE
            btnCenter.text = "后"
            )
        ELSE (
            max vpt back
            front = TRUE
            btnCenter.text = "前"
            )
        if ckbAlign.checked do max zoomext sel
        )
    	
    on btnUp pressed do (
        max vpt top
        if ckbAlign.checked do max zoomext sel
        )
    	
    on btnDown pressed do (
        max vpt bottom
        if ckbAlign.checked do max zoomext sel
        )
    	
    on btnLeft pressed do (
        max vpt left
        if ckbAlign.checked do max zoomext sel
        )
    
    on btnRight pressed do (
        max vpt right
        if ckbAlign.checked do max zoomext sel
        )
    
    on btnClipping pressed do (
        actionMan.executeAction 0 "374"
        )
    )


createDialog rltNavigator
