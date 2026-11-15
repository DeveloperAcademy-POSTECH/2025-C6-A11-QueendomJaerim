# /qa가 올릴 앱 버전을 정하는 순수 함수. 애플에 접속하지 않으므로 사례 표로 확인할 수 있다.
module QaVersion
  # 이 상태만 "아직 제출하지 않음"으로 본다. 그 밖의 상태(모르는 상태 포함)는 제출된 버전이다.
  # 제출된 버전은 출시 대상이라 /qa가 건드리면 안 되고, 승인 이후에는 애플이 새 빌드를 거부할 수 있다.
  UNSUBMITTED_STATES = ["PREPARE_FOR_SUBMISSION"].freeze

  # develop_version: "1.2.2"
  # store_versions:  [["1.2.1", "READY_FOR_SALE"], ["1.2.2", "PREPARE_FOR_SUBMISSION"]]
  # 반환: { version:, bumped:, highest_submitted: }
  def self.decide(develop_version, store_versions)
    develop = parse(develop_version)

    submitted = store_versions
                .reject { |_, state| UNSUBMITTED_STATES.include?(state) }
                .map { |version, _| version }
    highest = submitted.max_by { |version| parse(version) }

    if highest.nil? || (parse(highest) <=> develop) < 0
      { version: develop_version, bumped: false, highest_submitted: highest }
    else
      parts = parse(highest)
      parts[2] += 1
      { version: parts.join("."), bumped: true, highest_submitted: highest }
    end
  end

  def self.parse(version)
    unless version.to_s =~ /\A\d+\.\d+\.\d+\z/
      raise ArgumentError, "x.y.z 형식이 아닌 버전입니다: #{version.inspect}"
    end

    version.split(".").map(&:to_i)
  end
end
