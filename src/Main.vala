public static int main(string[] args) {
    var app = new Morghulis();

    ensure_types();
    return app.run(args);
}
