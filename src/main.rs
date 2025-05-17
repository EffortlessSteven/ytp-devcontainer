use anyhow::Result;
use clap::Parser;

#[derive(Parser)]
#[command(author, version, about, long_about = None)]
struct Cli {
    /// The name to greet
    #[arg(short, long, default_value = "world")]
    name: String,
}

fn main() -> Result<()> {
    let cli = Cli::parse();
    println!("Hello, {}!", cli.name);
    Ok(())
} 