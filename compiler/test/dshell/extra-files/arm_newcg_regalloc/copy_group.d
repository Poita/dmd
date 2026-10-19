// A register is given the register of what it is copied to or from as soon as either
// is allocated, where that register is free, before others take the register.

struct Weapon
{
    float damage;
    int burstCount;
    float burstInterval, cooldown, reloadTime, aimTime;
}

float copies0_dps(const ref Weapon w)
{
    const cycleDamage = w.damage * w.burstCount;
    float cycleTime;
    if (w.burstCount > 1)
    {
        const interval = w.burstInterval > 0 ? w.burstInterval : w.cooldown;
        const reload = w.reloadTime > 0 ? w.reloadTime : w.cooldown;
        cycleTime = (w.burstCount - 1) * interval + reload;
    }
    else
        cycleTime = w.cooldown;
    cycleTime += w.aimTime;
    if (cycleTime <= 0)
        return 0;
    return cycleDamage / cycleTime;
}

void main()
{
    auto w = Weapon(10, 3, 0.5, 2, 0, 1);
    assert(copies0_dps(w) == 30.0f / 4);
    w.burstCount = 1;
    assert(copies0_dps(w) == 10.0f / 3);
}
