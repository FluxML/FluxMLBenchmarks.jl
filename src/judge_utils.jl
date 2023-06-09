using BenchmarkCI: printresultmd, CIResult
using PkgBenchmark: BenchmarkJudgement
using Markdown

"""
    markdown_report(judgement::BenchmarkJudgement)

Return markdown content (String) by the result of BenchmarkTools.judge.
"""
function markdown_report(judgement::BenchmarkJudgement)
    md = sprint(printresultmd, CIResult(judgement = judgement))
    md = replace(md, ":x:" => "❌")
    md = replace(md, ":white_check_mark:" => "✅")
    return md
end


"""
    display_markdown_report(report_md)

Display the content of the report after parsed by Markdown.parse.

* report_md: the result of [`markdown_report`](@ref)
"""
display_markdown_report(report_md) = display(Markdown.parse(report_md))
