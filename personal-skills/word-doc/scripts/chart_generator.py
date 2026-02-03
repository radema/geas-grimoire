#!/usr/bin/env python3
"""
Chart Generator - Seaborn wrapper for creating styled charts.

Generates chart images with optional custom color palettes to match
company templates.

Dependencies: seaborn, matplotlib, pandas

Usage:
    python chart_generator.py --type line --data data.csv --x month --y revenue --output chart.png
    python chart_generator.py --type bar --data data.csv --x category --y count --palette "#1a73e8,#34a853"
"""

import argparse
import json
import sys
from pathlib import Path

try:
    import matplotlib.pyplot as plt
    import pandas as pd
    import seaborn as sns
except ImportError as e:
    print(f"Missing dependency: {e.name}")
    print("Install with: pip install seaborn matplotlib pandas")
    sys.exit(1)


SUPPORTED_CHART_TYPES = ["line", "bar", "scatter", "area", "pie", "heatmap", "box"]


def load_palette(palette_arg: str = None, template_dir: Path = None) -> list[str]:
    """
    Load color palette from:
    1. CLI argument (comma-separated hex codes)
    2. palette.json in template directory
    3. Seaborn default
    """
    if palette_arg:
        return [c.strip() for c in palette_arg.split(",")]
    
    if template_dir:
        palette_file = template_dir / "palette.json"
        if palette_file.exists():
            try:
                with open(palette_file) as f:
                    data = json.load(f)
                    if isinstance(data, list):
                        return data
                    elif isinstance(data, dict) and "colors" in data:
                        return data["colors"]
            except Exception as e:
                print(f"Warning: Could not load palette.json: {e}")
    
    return None  # Use seaborn default


def generate_chart(
    chart_type: str,
    data_path: Path,
    x_col: str,
    y_col: str,
    output_path: Path,
    palette: list[str] = None,
    title: str = None,
    hue: str = None,
    figsize: tuple = (10, 6),
    dpi: int = 150
) -> bool:
    """Generate a chart and save to file."""
    
    # Load data
    try:
        if data_path.suffix == ".csv":
            df = pd.read_csv(data_path)
        elif data_path.suffix in [".xlsx", ".xls"]:
            df = pd.read_excel(data_path)
        elif data_path.suffix == ".json":
            df = pd.read_json(data_path)
        else:
            print(f"Unsupported data format: {data_path.suffix}")
            return False
    except Exception as e:
        print(f"Error loading data: {e}")
        return False
    
    # Validate columns
    if x_col and x_col not in df.columns:
        print(f"Error: Column '{x_col}' not found. Available: {list(df.columns)}")
        return False
    if y_col and y_col not in df.columns:
        print(f"Error: Column '{y_col}' not found. Available: {list(df.columns)}")
        return False
    
    # Set style
    sns.set_theme(style="whitegrid")
    if palette:
        sns.set_palette(palette)
    
    # Create figure
    fig, ax = plt.subplots(figsize=figsize)
    
    try:
        if chart_type == "line":
            sns.lineplot(data=df, x=x_col, y=y_col, hue=hue, ax=ax, marker="o")
        
        elif chart_type == "bar":
            sns.barplot(data=df, x=x_col, y=y_col, hue=hue, ax=ax)
        
        elif chart_type == "scatter":
            sns.scatterplot(data=df, x=x_col, y=y_col, hue=hue, ax=ax, s=100)
        
        elif chart_type == "area":
            # Area chart using matplotlib fill_between
            if hue:
                for name, group in df.groupby(hue):
                    ax.fill_between(group[x_col], group[y_col], alpha=0.6, label=name)
                ax.legend()
            else:
                ax.fill_between(df[x_col], df[y_col], alpha=0.6)
            ax.set_xlabel(x_col)
            ax.set_ylabel(y_col)
        
        elif chart_type == "pie":
            # Pie chart
            plt.close(fig)
            fig, ax = plt.subplots(figsize=figsize)
            colors = palette if palette else None
            ax.pie(df[y_col], labels=df[x_col], autopct="%1.1f%%", colors=colors)
            ax.axis("equal")
        
        elif chart_type == "heatmap":
            # Pivot data for heatmap
            plt.close(fig)
            fig, ax = plt.subplots(figsize=figsize)
            pivot = df.pivot_table(values=y_col, index=x_col, aggfunc="mean")
            sns.heatmap(pivot, annot=True, fmt=".1f", ax=ax, cmap="Blues")
        
        elif chart_type == "box":
            sns.boxplot(data=df, x=x_col, y=y_col, hue=hue, ax=ax)
        
        else:
            print(f"Unsupported chart type: {chart_type}")
            print(f"Supported types: {SUPPORTED_CHART_TYPES}")
            return False
        
        # Add title if provided
        if title:
            ax.set_title(title, fontsize=14, fontweight="bold")
        
        # Rotate x labels if needed
        if chart_type not in ["pie", "heatmap"]:
            plt.xticks(rotation=45, ha="right")
        
        # Tight layout
        plt.tight_layout()
        
        # Save
        output_path.parent.mkdir(parents=True, exist_ok=True)
        fig.savefig(output_path, dpi=dpi, bbox_inches="tight", facecolor="white")
        plt.close(fig)
        
        print(f"✅ Chart saved to: {output_path}")
        return True
        
    except Exception as e:
        print(f"Error generating chart: {e}")
        plt.close(fig)
        return False


def main():
    parser = argparse.ArgumentParser(
        description="Generate styled charts using Seaborn"
    )
    parser.add_argument(
        "--type", "-t",
        required=True,
        choices=SUPPORTED_CHART_TYPES,
        help=f"Chart type: {SUPPORTED_CHART_TYPES}"
    )
    parser.add_argument(
        "--data", "-d",
        required=True,
        help="Data file (CSV, Excel, or JSON)"
    )
    parser.add_argument(
        "--x",
        required=True,
        help="X-axis column name"
    )
    parser.add_argument(
        "--y",
        required=True,
        help="Y-axis column name"
    )
    parser.add_argument(
        "--output", "-o",
        required=True,
        help="Output image path"
    )
    parser.add_argument(
        "--palette",
        help="Comma-separated hex colors (e.g., '#1a73e8,#34a853')"
    )
    parser.add_argument(
        "--template-dir",
        help="Template directory to look for palette.json"
    )
    parser.add_argument(
        "--title",
        help="Chart title"
    )
    parser.add_argument(
        "--hue",
        help="Column for color grouping"
    )
    parser.add_argument(
        "--width",
        type=float,
        default=10,
        help="Figure width in inches"
    )
    parser.add_argument(
        "--height",
        type=float,
        default=6,
        help="Figure height in inches"
    )
    parser.add_argument(
        "--dpi",
        type=int,
        default=150,
        help="Output DPI"
    )
    
    args = parser.parse_args()
    
    data_path = Path(args.data)
    output_path = Path(args.output)
    template_dir = Path(args.template_dir) if args.template_dir else None
    
    if not data_path.exists():
        print(f"Error: Data file not found: {data_path}")
        sys.exit(1)
    
    # Load palette
    palette = load_palette(args.palette, template_dir)
    
    success = generate_chart(
        chart_type=args.type,
        data_path=data_path,
        x_col=args.x,
        y_col=args.y,
        output_path=output_path,
        palette=palette,
        title=args.title,
        hue=args.hue,
        figsize=(args.width, args.height),
        dpi=args.dpi
    )
    
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
