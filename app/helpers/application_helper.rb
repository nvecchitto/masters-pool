module ApplicationHelper
  # Returns a Tailwind text-color class based on a golf score relative to par.
  def score_color_class(score)
    if score < 0
      "text-red-400"    # under par → red (golf convention)
    elsif score > 0
      "text-blue-400"   # over par → blue
    else
      "text-gray-300"   # even
    end
  end

  # Returns the display label for a hole score type.
  def hole_score_label(type)
    case type
    when "double_eagle" then "-3"
    when "eagle"        then "-2"
    when "birdie"       then "-1"
    when "par"          then "E"
    when "bogey"        then "+1"
    when "double_bogey" then "+2"
    when "triple_bogey" then "+3"
    when "worse"        then "+4"
    else                     ""
    end
  end

  # Returns Tailwind classes for the hole score cell decoration.
  # Eagles/double-eagles: double circle; birdies: single circle;
  # bogeys: single square; double-bogey+: double square.
  def hole_score_classes(type)
    base = "inline-flex items-center justify-center w-7 h-7 text-xs font-bold font-mono"
    case type
    when "double_eagle"
      "#{base} rounded-full border-2 border-yellow-300 outline outline-2 outline-offset-2 outline-yellow-300 text-yellow-300"
    when "eagle"
      "#{base} rounded-full border-2 border-yellow-400 outline outline-2 outline-offset-2 outline-yellow-400 text-yellow-400"
    when "birdie"
      "#{base} rounded-full border-2 border-yellow-400 text-yellow-400"
    when "par"
      "#{base} text-gray-300"
    when "bogey"
      "#{base} border-2 border-blue-400 text-blue-400"
    when "double_bogey"
      "#{base} border-2 border-blue-500 outline outline-2 outline-offset-2 outline-blue-500 text-blue-500"
    when "triple_bogey", "worse"
      "#{base} border-2 border-blue-700 outline outline-2 outline-offset-2 outline-blue-700 text-blue-400"
    else
      "#{base} text-gray-700"
    end
  end

  # Returns Tailwind badge classes for a Tournament status label.
  def tournament_status_classes(tournament)
    case tournament.status
    when "in_progress" then "bg-green-500 text-white"
    when "complete"    then "bg-gray-600 text-gray-200"
    else                    "bg-yellow-600 text-white"  # upcoming
    end
  end
end
