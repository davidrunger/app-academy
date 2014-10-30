# == Schema Information
#
# Table name: cat_rental_requests
#
#  id           :integer          not null, primary key
#  cat_id       :integer          not null
#  start_date   :date             not null
#  end_date     :date             not null
#  status       :string(255)      default("PENDING")
#  created_at   :datetime
#  updated_at   :datetime
#  requester_id :integer          not null
#

class CatRentalRequest < ActiveRecord::Base
  validates :cat_id, :start_date, :end_date, :status, presence: true
  validates :status, inclusion: { in: ["PENDING", "APPROVED", "DENIED"],
    message: "YOU CAN NOT RENT A KITTY THAT WAY" }
  validate :no_overlapping_requests
  after_initialize :set_default_status
  
  belongs_to(:cat)
  belongs_to(
    :requester,
    class_name: 'User',
    foreign_key: :requester_id,
    primary_key: :id
  )
  
  def overlapping_requests
    query = CatRentalRequest.where(<<-SQL)
      ('#{start_date}' BETWEEN start_date AND end_date)
      OR ('#{end_date}' BETWEEN start_date AND end_date)
      OR start_date BETWEEN '#{start_date}' AND '#{end_date}'
    SQL
    query = query.where("cat_id = #{cat_id}")
    
    if self.persisted?
      query.where("id != #{id}")
    else
      query
    end
  end
  
  def no_overlapping_requests
    return unless cat_id && start_date && end_date
    approved_requests = overlapping_requests.where("status = 'APPROVED'")
    unless approved_requests.count == 0
      errors[:rental_request] <<
        "Kitty #{Cat.find(cat_id).name} is already rented during that time"
    end
  end
  
  def set_default_status
    @status ||= 'PENDING'
  end
  
  def approve!
    CatRentalRequest.transaction do
      overlapping_requests.update_all(status: "DENIED")
      self.update(status: "APPROVED")
    end
  end
  
  def deny!
    self.update!(status: "DENIED")
  end
  
  def pending?
    status == 'PENDING'
  end
end
