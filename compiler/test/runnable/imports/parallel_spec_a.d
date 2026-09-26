module imports.parallel_spec_a;

template enforce()
{
    T enforce(T)(T value)
    {
        return value;
    }
}

T enforce()()
{
}

alias errnoEnforce = enforce;
