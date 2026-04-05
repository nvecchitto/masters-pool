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

  # Returns Tailwind badge classes for a Tournament status label.
  def tournament_status_classes(tournament)
    case tournament.status
    when "in_progress" then "bg-green-500 text-white"
    when "complete"    then "bg-gray-600 text-gray-200"
    else                    "bg-yellow-600 text-white"  # upcoming
    end
  end
end
