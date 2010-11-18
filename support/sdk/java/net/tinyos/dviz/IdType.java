package net.tinyos.dviz;

public enum IdType {

    IGNORE, COUNT, ACCUMULATE, LATEST;

    private int arg;

    private IdType() {
        arg = 0;
    }

    public int getArg() {
        return arg;
    }

    @Override
    public String toString() {
        if(this==IdType.ACCUMULATE || this==IdType.LATEST) { 
            return this.name() + ":" + arg;
        } else {
            return this.name();
        }
    }

    public static IdType fromString(String string) {
        String[] s = string.split(":");
        for(IdType type : values()) {
            if (type.name().equals(s[0])) {
                if(type==IdType.ACCUMULATE || type==IdType.LATEST) { 
                    type.arg = Integer.valueOf(s[1]);
                }
                return type;
            }
        }
        return null;
    }
}

