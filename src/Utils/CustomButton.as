class CustomButton {
    bool visible = true;
    bool isHovered = false;
    
    string action = "none";
    string label = "";
    int x = 0;
    int y = 0;
    int width = 30;
    int height = 30;
    int fontSize = 20;
    vec4 color = vec4(1, 1, 1, 1);
    vec4 hoverColor = vec4(0, 1, 0, 1);
    string hintText = "";

    CustomButton(
        string action, string label, int x = 5, int y = 5, int width = 30, int height = 30, int fontSize = 20, 
        vec4 color = vec4(1, 1, 1, 1), vec4 hoverColor = vec4(0, 1, 0, 1), string hintText = ""
    ) {
        this.action = action;
        this.label = label;
        this.x = x;
        this.y = y;
        this.width = width;
        this.height = height;
        this.fontSize = fontSize;
        this.color = color;
        this.hoverColor = hoverColor;
        this.hintText = hintText;
    }
};