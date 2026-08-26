; ---------------------------------------------------------------------------
; O2om — Asset & Resource Manager with Standalone Binary Extraction
; ---------------------------------------------------------------------------

class O2omResources {
    static resourceDir := ""
    static exerciseImg := ""
    static iconPath    := ""

    static Init() {
        candidates := [
            A_ScriptDir "\assets",
            A_ScriptDir "\..\assets",
            A_WorkingDir "\assets"
        ]

        for candidate in candidates {
            img := candidate "\exercises_bg.png"
            ico := candidate "\o2om.ico"
            if (FileExist(img) && FileExist(ico)) {
                this.resourceDir := candidate
                this.exerciseImg := img
                this.iconPath    := ico
                return
            }
        }

        appDataAssets := A_AppData "\O2om\assets"
        try DirCreate(appDataAssets)

        this.exerciseImg := appDataAssets "\exercises_bg.png"
        this.iconPath    := appDataAssets "\o2om.ico"

        try {
            if (!FileExist(this.exerciseImg)) {
                FileInstall("assets\exercises_bg.png", this.exerciseImg, 1)
            }
        }
        try {
            if (!FileExist(this.iconPath)) {
                FileInstall("assets\o2om.ico", this.iconPath, 1)
            }
        }

        for candidate in candidates {
            if (!FileExist(this.exerciseImg) && FileExist(candidate "\exercises_bg.png"))
                this.exerciseImg := candidate "\exercises_bg.png"
            if (!FileExist(this.iconPath) && FileExist(candidate "\o2om.ico"))
                this.iconPath := candidate "\o2om.ico"
        }
    }

    static GetExerciseImage() {
        if (this.exerciseImg == "" || !FileExist(this.exerciseImg))
            this.Init()
        return FileExist(this.exerciseImg) ? this.exerciseImg : ""
    }

    static GetIcon() {
        if (this.iconPath == "" || !FileExist(this.iconPath))
            this.Init()
        return FileExist(this.iconPath) ? this.iconPath : ""
    }
}
