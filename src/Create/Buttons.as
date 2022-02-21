namespace Button {

CustomButton@ create = CustomButton(
    "create", Icons::FilePowerpointO, 
    1708, 1310,
    50, 50, 36,
    vec4(1, 1, 1, 1), vec4(1. / 255, 80. / 255, 40. / 255, 1),
    "Create new MacroPart"
);
CustomButton@ cancel = CustomButton(
    "cancel", Icons::TimesCircle, 
    1708, 1310,
    50, 50, 36,
    vec4(1, 1, 1, 1), vec4(1. / 255, 80. / 255, 40. / 255, 1),
    "Cancel creating MacroPart"
);
CustomButton@ mtgAirmode = CustomButton(
    "airmode", Icons::Cloud, 
    138, 998,
    50, 50, 32,
    vec4(1, 1, 1, 1), vec4(1. / 255, 80. / 255, 40. / 255, 1),
    "Air macroblock mode"
);
CustomButton@ mtgClear = CustomButton(
    "clear", Icons::Trash, 
    193, 998,
    50, 50, 32,
    vec4(1, 1, 1, 1), vec4(1. / 255, 80. / 255, 40. / 255, 1),
    "Clear map"
);
CustomButton@ mtgGenerate = CustomButton(
    "generate", Icons::Random, 
    248, 998,
    50, 50, 32,
    vec4(1, 1, 1, 1), vec4(1. / 255, 80. / 255, 40. / 255, 1),
    "Open generate track popup"
);
CustomButton@ mtgCreate = CustomButton(
    "create", Icons::FilePowerpointO, 
    303, 998,
    50, 50, 32,
    vec4(1, 1, 1, 1), vec4(1. / 255, 80. / 255, 40. / 255, 1),
    "Create new MacroPart"
);
CustomButton@ mtgEdit = CustomButton(
    "edit", Icons::PencilSquareO, 
    358, 998,
    50, 50, 32,
    vec4(1, 1, 1, 1), vec4(1. / 255, 80. / 255, 40. / 255, 1),
    "Edit MacroPart"
);
CustomButton@ mtgCancel = CustomButton(
    "cancel", Icons::TimesCircle, 
    358, 998,
    50, 50, 32,
    vec4(1, 1, 1, 1), vec4(1. / 255, 80. / 255, 40. / 255, 1),
    "Cancel creating MacroPart"
);

CustomButton@[]@ list = {create, cancel, mtgAirmode, mtgClear, mtgGenerate, mtgCreate, mtgEdit, mtgCancel};

}